require 'rails_helper'

RSpec.describe "/cart", type: :request do
  let(:product) { create(:product, name: "Test Product", price: 10.0) }
  let(:product2) { create(:product, name: "Test Product 2", price: 20.0) }

  describe "POST /cart" do
    context "with valid parameters" do
      it "creates a new cart and adds the product" do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(1)
        expect(json['products'][0]['name']).to eq("Test Product")
        expect(json['products'][0]['quantity']).to eq(2)
        expect(json['products'][0]['unit_price']).to eq(10.0)
        expect(json['products'][0]['total_price']).to eq(20.0)
        expect(json['total_price']).to eq(20.0)
      end

      it "increases cart count" do
        expect {
          post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        }.to change(Cart, :count).by(1)
      end
    end

    context "with invalid quantity" do
      it "returns error for quantity zero" do
        post '/cart', params: { product_id: product.id, quantity: 0 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /cart" do
    context "when cart exists in session" do
      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
      end

      it "returns the current cart" do
        get '/cart', as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(1)
        expect(json['total_price']).to eq(20.0)
      end
    end

    context "when no cart exists in session" do
      it "returns not found" do
        get '/cart', as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /cart/add_item" do
    context "when cart exists" do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it "adds a new product to the cart" do
        post '/cart/add_item', params: { product_id: product2.id, quantity: 1 }, as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(2)
        expect(json['total_price']).to eq(30.0)
      end

      context "when the product already is in the cart" do
        it "updates the quantity of the existing item in the cart" do
          post '/cart/add_item', params: { product_id: product.id, quantity: 2 }, as: :json

          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json['products'][0]['quantity']).to eq(3)
          expect(json['products'][0]['total_price']).to eq(30.0)
          expect(json['total_price']).to eq(30.0)
        end
      end
    end

    context "when no cart exists in session" do
      it "returns not found" do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /cart/:product_id" do
    context "when cart exists" do
      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        post '/cart/add_item', params: { product_id: product2.id, quantity: 1 }, as: :json
      end

      it "removes the product from the cart" do
        delete "/cart/#{product.id}", as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(1)
        expect(json['total_price']).to eq(20.0)
      end

      it "returns not found when product is not in cart" do
        delete "/cart/99999", as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Produto não encontrado no carrinho")
      end

      it "returns empty cart after removing last product" do
        delete "/cart/#{product.id}", as: :json
        delete "/cart/#{product2.id}", as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['products']).to be_empty
        expect(json['total_price']).to eq(0.0)
      end
    end

    context "when no cart exists in session" do
      it "returns not found" do
        delete "/cart/#{product.id}", as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
