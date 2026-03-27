require 'rails_helper'

RSpec.describe CartItem, type: :model do
  context 'when validating' do
    it 'is valid with valid attributes' do
      cart_item = build(:cart_item)
      expect(cart_item).to be_valid
    end

    it 'validates numericality of quantity' do
      cart_item = build(:cart_item, quantity: -1)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:quantity]).to include("must be greater than 0")
    end
  end

  context 'associations' do
    it { expect(described_class.reflect_on_association(:cart).macro).to eq(:belongs_to) }
    it { expect(described_class.reflect_on_association(:product).macro).to eq(:belongs_to) }
  end
end
