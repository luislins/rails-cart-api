# Shopping cart API

A Rails API for a shopping cart with an abandonment lifecycle: carts that go
quiet are flagged, and carts that stay quiet are deleted. Built as a take-home
technical challenge.

Rails 7.1 · PostgreSQL · Redis · Sidekiq · RSpec · Docker

## The domain

A cart belongs to a browser session and holds line items. Every change
recalculates the total and stamps the last interaction. A scheduled job then
walks the carts on a clock:

```
     any change            3h of silence           7 days of silence
  ───────────────►  active ──────────────► abandoned ──────────────► deleted
   last_interaction_at = now
```

Both transitions live in one hourly job, because they are the same question
asked at two thresholds: how long has this cart been untouched?

## Endpoints

| Method | Endpoint | |
|---|---|---|
| `POST` | `/cart` | Create a cart (or reuse the session's) and add the first product |
| `GET` | `/cart` | Show the session's cart |
| `POST` | `/cart/add_item` | Add a product, or increase its quantity if already there |
| `DELETE` | `/cart/:product_id` | Remove a product from the cart |
| | `/products` | Full CRUD |

**Add an item**

```json
POST /cart/add_item
{ "product_id": 1, "quantity": 2 }
```

```json
200 OK

{
  "id": 1,
  "products": [
    { "id": 1, "name": "Coffee", "quantity": 2, "unit_price": 14.9, "total_price": 29.8 }
  ],
  "total_price": 29.8
}
```

Errors are explicit: unknown product and empty cart return `404`, a quantity of
zero or less returns `422`.

## Technical decisions

**The total is never set by a caller.** `Cart#recalculate!` is the only writer
of `total_price`, and it recomputes from the line items with a single SQL sum
rather than trusting an incoming number. It stamps `last_interaction_at` in the
same update, so "the total changed" and "the cart was touched" can never drift
apart — which matters, because the abandonment clock reads that column.

**Adding a product that's already in the cart increases its quantity.** No
duplicate line items, so the cart never shows the same product twice.

**Abandonment is two thresholds, one job.** `MarkCartAsAbandonedJob` runs
hourly via `sidekiq-scheduler` and does both passes. The filtering is done in
SQL (`where last_interaction_at <= ?`) so the job touches only the rows that
can change, and the model methods re-check the same condition — cheap
protection against being called directly from somewhere else.

**sidekiq-scheduler instead of cron.** The schedule lives in
`config/sidekiq.yml`, versioned with the code, and runs wherever the workers
run. No machine-level configuration to reproduce in another environment.

**Cart identity comes from the session.** No user model in scope for this
challenge, so `session[:cart_id]` is the owner. The concern that resolves it
(`CurrentCart`) is deliberately separate from the controller, so introducing
real authentication later means changing one method.

**The cart payload is built explicitly**, with `includes(:product)` on the
items — the response shape is a decision, not whatever `to_json` happens to
produce, and it costs one query instead of one per line.

## Running it

```bash
docker compose up --build
```

Postgres, Redis, the Rails server and a Sidekiq worker come up together;
`db:prepare` runs on boot. The API answers on http://localhost:3000.

Without Docker, with Postgres 16 and Redis 7 already running:

```bash
bundle install
bin/rails db:prepare
bundle exec sidekiq        # in another shell
bin/rails server
```

## Tests

```bash
bundle exec rspec
```

Specs cover the models (totals, quantity merging, the abandonment thresholds),
the requests (each endpoint and each error path), the routing, and the
scheduled job.

## The Sidekiq dashboard

Mounted at `/sidekiq`. It is open in development and behind HTTP Basic
everywhere else:

```bash
SIDEKIQ_WEB_USER=...
SIDEKIQ_WEB_PASSWORD=...
```

If either variable is missing outside development, the dashboard refuses every
request rather than falling open — a variable forgotten during a deploy must
not silently reopen a page that can replay and delete jobs.
