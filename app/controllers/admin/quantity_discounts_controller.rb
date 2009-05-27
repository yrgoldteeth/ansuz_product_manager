class Admin::QuantityDiscountsController < ApplicationController
  unloadable # This is required if you subclass a controller provided by the base rails app
  layout 'admin'
  before_filter :load_quantity_discount,     :only => [:show, :edit, :update, :destroy]
  before_filter :load_new_quantity_discount, :only => [:new, :create]
  before_filter :load_quantity_discounts,    :only => [:index]

  protected
  def load_quantity_discount
    @quantity_discount = Ansuz::NFine::QuantityDiscount.find(params[:id], :include => [:product])
    @product = Ansuz::NFine::Product.find(params[:product_id])
  end

  def load_new_quantity_discount
    @quantity_discount = Ansuz::NFine::QuantityDiscount.new(params[:quantity_discount])
    @product = Ansuz::NFine::Product.find(params[:product_id])
  end

  def load_quantity_discounts
    @quantity_discounts = Ansuz::NFine::QuantityDiscount.find_all_by_product_id(params[:product_id])
    @product = Ansuz::NFine::Product.find(params[:product_id])
  end

  public
  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    if @quantity_discount.save
      flash[:notice] = 'Quantity Discount was successfully created.'
      redirect_to admin_products_path
    else
      flash.now[:error] = "There was a problem creating the Quantity Discount.  Please try again."
      render :action => "new" 
    end
  end

  def update
    if @quantity_discount.update_attributes(params[:quantity_discount])
#      @product = Ansuz::NFine::Product.find(@quantity_discount.quantity_discount_id)
      flash[:notice] = 'Ansuz::NFine::QuantityDiscount was successfully updated.'
      redirect_to  admin_products_path
    else
      flash.now[:error] = "There was a problem updating the Quantity Discount.  Please try again."
      render :action => "edit" 
    end
  end

  def destroy
    @quantity_discount.destroy
    flash[:notice] = "Product's Quantity Discount was deleted."
    redirect_to admin_products_path
  end
end
