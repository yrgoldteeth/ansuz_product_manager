class CartsController < ApplicationController
  unloadable # This is required if you subclass a controller provided by the base rails app
  before_filter :login_required#, :only => [:ordered, :previous]
  before_filter :load_current_cart, :only => [:show, :checkout, :index, :add, :update, :apply_coupon]
  before_filter :load_cart,  :only => [:previous]
  before_filter :load_carts, :only => [:ordered]
#  helper :carts

  private
  def load_current_cart #for some reason, extending users with this doesn't always find their cart, but creates a new one.
    if current_user.carts.find(:first, :order=> 'id desc')
      @cart = current_user.carts.find(:first, :order => 'id desc')
      @line_items = @cart.line_items
    else
      @cart = Ansuz::NFine::Cart.create(:user_id => current_user.id)
    end
  end

  def load_carts
    @carts = current_user.carts.ordered.find(:all)
  end
  def load_cart
    @cart = current_user.carts.find(params[:id], :include => [:line_items, { :person => [:addresses] }])
  end
public
  def index
    redirect_to :action => 'show'
  end

  # GET /cart/1
  # GET /cart/1.xml
  def show
  end

  def checkout
    @step = params[:step].to_i
    case @step
    when 6
      handle_process_order
    when 5
      handle_confirmation_page
    when 4
      handle_shipment
    when 3
      handle_billing_address
    when 2
      handle_shipping_address
    else
      handle_pre_shipping_address
    end
  end

  def handle_user_information
    if @cart.cart_user_information
      @user_information = @cart.cart_user_information
    else
      @user_information = @cart.create_cart_user_information
    end
    @cart.save
    render :action => 'user_information'
  end


  def ordered
  end

  def update
    case params[:form_action]
    when "Remove Selected"
    line_item_ids = params.keys.map do |key|
      if key =~ /select_([\d]+)/
        $1.to_i
      end
    end
      @line_items = Ansuz::NFine::LineItem.find line_item_ids
      @line_items.map(&:destroy)
      @cart.update_subtotal!
      flash[:notice] = "Item has been removed from cart"
      redirect_to cart_path
    when "Clear Cart"
      @cart.line_items.map(&:destroy)
      @cart.update_subtotal
      flash[:notice] = "Items have been removed from cart"
      redirect_to cart_path
    when "Update Quantity"
      params[:quantity_line_item_id].each_with_index do |line_item_id, i|
        line_item = Ansuz::NFine::LineItem.find(line_item_id)
        quantity = params[:quantity][i].to_i
        if !(quantity > 0)
          line_item.destroy
        else
          price = line_item.product.quantity_price(quantity) * 100
          line_item.quantity = quantity
          line_item.price_in_cents = price.to_i
          line_item.save
        end
      end
      flash[:notice] = "Quantity updated successfully"
      redirect_to cart_path
    end
  end

  def add
      product_params = params[:product]
      qty = product_params[:qty].to_i
      product_id = product_params[:id]
      if product_params[:details]
        details = product_params[:details]
      end

      if qty > 0
        product = Ansuz::NFine::Product.find(product_id, :include => [:quantity_discounts])
        price = product.quantity_price(qty)
        options = {}
        options[:price_in_cents] = (price * 100).to_i
        options[:quantity] = qty
        options[:product_id] = product_id
        options[:configuration] = details
          logger.info "Adding product: #{product.inspect}.  Quantity: #{qty}."
        @cart.add(product, options)
      end
      redirect_to :controller => 'products'
  end 

  protected
  def handle_shipping_address
    @person = (@cart.user && @cart.user.person) || @cart.person
    if @person
      @person.update_attributes(params['person'])
    else
      @person = Person.new(params['person'])
      @person.user = current_user if logged_in?
      @cart.person = @person
    end
    if @person.shipping_address
      @address = @person.shipping_address
      @address.update_attributes(params['address'])
    else
      @address = Address.new(params['address'])
      @address.address_type = 'Shipping'
      @person.addresses << @address
    end
    unless @person.save && @address.errors.length == 0
      @step = 1
      render :action => 'checkout_shipping_address'
    else
      @cart.reload
      @address = @person.shipping_address
      @address ||= Address.new
      if params["same_as_shipping"]
        if @person && @person.shipping_address
          if @person.billing_address
            @baddress = @person.billing_address
            @baddress.update_attributes(params['address'])
          else
            @baddress = @person.shipping_address.clone
            @baddress.address_type = "Billing"
            @baddress.save
          end
        end
        @step = 3
        render :action => 'checkout_shipment'
      else
        render :action => 'checkout_billing_address'
      end
    end
  end

  def handle_pre_shipping_address
    @person = @cart.proper_person
    @person ||= Person.new
    @address = @person.shipping_address
    @address ||= Address.new
    @step = 1
    render :action => 'checkout_shipping_address'
  end

  def handle_billing_address
    if @cart && @cart.billing_address
      @address = @cart.billing_address
      @address.update_attributes(params["address"]) if params[:address]
    else
      @address = Address.new(params["address"])
      @address.address_type = "Billing"
      @address.email = @cart.shipping_address.email
      @person = @cart.proper_person
      @person.addresses << @address
    end
    unless @cart.save && @address.errors.length == 0
      @step = 2
      render :action => 'checkout_billing_address'
    else
      #@cart.update_shipping!
      @cart.update_total!
      #@credit_card_transaction = CreditCardTransaction.new # TODO: Implement this
      render :action => 'checkout_shipment'
    end
  end

  def handle_shipment
    @cart.shipping_method = params[:shipping_method]
    @cart.rush_shipping   = params[:rush_shipping]
    @cart.save
    render :action => 'checkout_payment'
  end

  def handle_process_order
    if params[:gift_message]
      @cart.gift_message = params[:gift_message]
      @cart.save
    end
    process_order = case RAILS_ENV
                    when 'development'
                      lambda{@cart.order!}
                    else
                      lambda{@cart.order_and(:purchase, :credit_card => @active_merchant_credit_card, :billing_address => @billing_address_hash)}
                    end
    if process_order.call
      cookies[:cart] = nil
      @step = 99
      @cart.reload
      @cart.save
      render :action => 'checkout_success'
    else
      if @cart.response && @cart.response.params
        flash.now[:error] = @cart.response.params["response_reason_text"]
      end
      render :action => 'checkout_payment'
    end
  end

  def handle_confirmation_page
    if @active_merchant_credit_card.valid?
      render :action => 'checkout_confirm'
    else
      @step = 4
      render :action => 'checkout_payment'
    end
  end

  public
  def apply_coupon
    if( request.xhr? )
      result = @cart.apply_coupon(params[:code])
      @cart.reload
      @cart.save
      status  = result[0]
      message = result[1]
      if(status == true)
        render :text => "<div class=\"notice\">#{message}</div>", :layout => false
      else
        render :text => "<div class=\"error\">#{message}</div>", :layout => false
      end
    end
  end

  def get_order_status
    @order = Cart.ordered.find_by_order_number params[:order_number]
    if @order
      if @order.email_address == params[:email_address]
        respond_to do |format|
          format.html {}
        end
      else
        flash[:error] = "The email address didn't match the email address on file for that order."
        redirect_to '/'
      end
    else
      flash[:error] = "There was no order with that order number in our records.  Please try again."
      redirect_to '/'
    end
  end
end
