require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe '#add_product' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }

    it 'adds a new product to the cart' do
      expect { cart.add_product(product, 2) }.to change { cart.cart_items.count }.by(1)
    end

    it 'increments quantity when product already exists' do
      cart.add_product(product, 1)
      expect { cart.add_product(product, 2) }.to change { cart.cart_items.find_by(product: product).quantity }.from(1).to(3)
    end

    it 'recalculates total price' do
      cart.add_product(product, 3)
      expect(cart.total_price.to_f).to eq(30.0)
    end
  end

  describe '#remove_product' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }

    before { cart.add_product(product, 2) }

    it 'removes the product from the cart' do
      expect { cart.remove_product(product.id) }.to change { cart.cart_items.count }.by(-1)
    end

    it 'recalculates total price' do
      cart.remove_product(product.id)
      expect(cart.total_price.to_f).to eq(0.0)
    end

    it 'returns nil when product is not in the cart' do
      expect(cart.remove_product(99999)).to be_nil
    end
  end

  describe 'mark_as_abandoned' do
    let(:shopping_cart) { create(:shopping_cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change { shopping_cart.abandoned? }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end
  end
end
