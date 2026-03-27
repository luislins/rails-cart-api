class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  def mark_as_abandoned
    update(abandoned: true) if last_interaction_at <= 3.hours.ago
  end

  def remove_if_abandoned
    destroy if abandoned? && last_interaction_at <= 7.days.ago
  end

  def update_total_price
    update(total_price: cart_items.joins(:product).sum('products.price * cart_items.quantity'))
  end

  def touch_interaction
    update(last_interaction_at: Time.current)
  end
end
