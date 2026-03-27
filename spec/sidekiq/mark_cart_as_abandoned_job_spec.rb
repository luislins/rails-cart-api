require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    context 'marking carts as abandoned' do
      it 'marks carts inactive for more than 3 hours as abandoned' do
        cart = create(:shopping_cart, last_interaction_at: 4.hours.ago)

        described_class.new.perform

        expect(cart.reload.abandoned?).to be true
      end

      it 'does not mark carts with recent interaction as abandoned' do
        cart = create(:shopping_cart, last_interaction_at: 1.hour.ago)

        described_class.new.perform

        expect(cart.reload.abandoned?).to be false
      end
    end

    context 'removing old abandoned carts' do
      it 'removes carts abandoned for more than 7 days' do
        cart = create(:shopping_cart, abandoned: true, last_interaction_at: 8.days.ago)

        expect { described_class.new.perform }.to change { Cart.count }.by(-1)
      end

      it 'does not remove recently abandoned carts' do
        cart = create(:shopping_cart, abandoned: true, last_interaction_at: 2.days.ago)

        expect { described_class.new.perform }.not_to change { Cart.count }
      end
    end
  end
end
