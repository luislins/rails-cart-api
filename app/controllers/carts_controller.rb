class CartsController < ApplicationController
  before_action :set_cart, only: [:show, :add_item, :remove_item]

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
    @cart = Cart.create(total_price: 0)
    session[:cart_id] = @cart.id

    add_product_to_cart

    render json: cart_response(@cart), status: :created
  end

  # POST /cart/add_item
  def add_item
    unless @cart
      return render json: { error: "Nenhum carrinho encontrado para esta sessão" }, status: :not_found
    end

    add_product_to_cart

    render json: cart_response(@cart)
  end

  # DELETE /cart/:product_id
  def remove_item
    unless @cart
      return render json: { error: "Nenhum carrinho encontrado para esta sessão" }, status: :not_found
    end

    cart_item = @cart.cart_items.find_by(product_id: params[:product_id])

    unless cart_item
      return render json: { error: "Produto não encontrado no carrinho" }, status: :not_found
    end

    cart_item.destroy
    @cart.update_total_price
    @cart.touch_interaction

    render json: cart_response(@cart)
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id])
  end

  def add_product_to_cart
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    if quantity <= 0
      return render json: { error: "Quantidade deve ser maior que zero" }, status: :unprocessable_entity
    end

    cart_item = @cart.cart_items.find_by(product_id: product.id)

    if cart_item
      cart_item.update(quantity: cart_item.quantity + quantity)
    else
      @cart.cart_items.create(product: product, quantity: quantity)
    end

    @cart.update_total_price
    @cart.touch_interaction
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
