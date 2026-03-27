module CurrentCart
  private

  def set_cart
    @cart = Cart.find(session[:cart_id])
  rescue ActiveRecord::RecordNotFound
    @cart = nil
  end

  def create_cart
    @cart = Cart.create(total_price: 0)
    session[:cart_id] = @cart.id
  end
end
