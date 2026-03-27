class CartsController < ApplicationController
  include CurrentCart

  before_action :set_cart, only: [:show, :add_item, :remove_item]
  before_action :require_cart, only: [:add_item, :remove_item]
  rescue_from ActiveRecord::RecordNotFound, with: :product_not_found

  # GET /cart
  def show
    if @cart
      render json: cart_response(@cart)
    else
      render json: { error: "Nenhum carrinho encontrado para esta sessão" }, status: :not_found
    end
  end

  # POST /cart
  def create
    create_cart
    product = Product.find(params[:product_id])

    return invalid_quantity unless valid_quantity?

    @cart.add_product(product, params[:quantity].to_i)

    render json: cart_response(@cart), status: :created
  end

  # POST /cart/add_item
  def add_item
    product = Product.find(params[:product_id])

    return invalid_quantity unless valid_quantity?

    @cart.add_product(product, params[:quantity].to_i)

    render json: cart_response(@cart)
  end

  # DELETE /cart/:product_id
  def remove_item
    removed = @cart.remove_product(params[:product_id])

    unless removed
      return render json: { error: "Produto não encontrado no carrinho" }, status: :not_found
    end

    render json: cart_response(@cart)
  end

  private

  def require_cart
    unless @cart
      render json: { error: "Nenhum carrinho encontrado para esta sessão" }, status: :not_found
    end
  end

  def valid_quantity?
    params[:quantity].to_i > 0
  end

  def invalid_quantity
    render json: { error: "Quantidade deve ser maior que zero" }, status: :unprocessable_entity
  end

  def product_not_found
    render json: { error: "Produto não encontrado" }, status: :not_found
  end

  def cart_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.price.to_f,
          total_price: (item.product.price * item.quantity).to_f
        }
      end,
      total_price: cart.total_price.to_f
    }
  end
end
