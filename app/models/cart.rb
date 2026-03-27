class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  def add_product(product, quantity)
    item = cart_items.find_by(product_id: product.id)

    if item
      item.update(quantity: item.quantity + quantity)
    else
      cart_items.create(product: product, quantity: quantity)
    end

    recalculate!
  end

  def remove_product(product_id)
    item = cart_items.find_by(product_id: product_id)
    return nil unless item

    item.destroy
    recalculate!
    item
  end

  def mark_as_abandoned
    update(abandoned: true) if last_interaction_at <= 3.hours.ago
  end

  def remove_if_abandoned
    destroy if abandoned? && last_interaction_at <= 7.days.ago
  end

  private

  def recalculate!
    update(
      total_price: cart_items.joins(:product).sum('products.price * cart_items.quantity'),
      last_interaction_at: Time.current
    )
  end
end
