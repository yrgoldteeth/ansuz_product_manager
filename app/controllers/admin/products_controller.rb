class Admin::ProductsController < Admin::BaseController
  unloadable # This is required if you subclass a controller provided by the base rails app
  layout 'admin'
  before_filter :load_product,     :only => [:show, :edit, :update, :destroy]
  before_filter :load_new_product, :only => [:new, :create]
  before_filter :load_products,    :only => [:index]

  protected
  def load_product
    @product = Ansuz::NFine::Product.find(params[:id])
  end

  def load_new_product
    @product = Ansuz::NFine::Product.new(params[:product])
  end

  def load_products
    @products = Ansuz::NFine::Product.find(:all, :order => 'created_at DESC')
  end

  # GET /products
  # GET /products.xml
  def index
    @products = Ansuz::NFine::Product.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @product = Ansuz::NFine::Product.find(params[:id])
    @quantity_discounts = @product.quantity_discounts

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/new
  # GET /products/new.xml
  def new
    @product = Ansuz::NFine::Product.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/1/edit
  def edit
    @product = Ansuz::NFine::Product.find(params[:id])
  end

  # POST /products
  # POST /products.xml
  def create
    @product = Ansuz::NFine::Product.new(params[:product])

    respond_to do |format|
      if @product.save
        flash[:notice] = 'Ansuz::NFine::Product was successfully created.'
        format.html { redirect_to(@product) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create_quantity_discount
    @product = Ansuz::NFine::Product.find(params[:id])
    @product.has_quantity_discount = true
    @product.save
    @quantity_discount = @product.quantity_discounts.create
    render :action => "quantity_discounts" 
  end

  def quantity_discounts
    @quantity_discount = Ansuz::QuantityDiscount.find(params[:id])
    render :action => "quantity_discounts"
  end

  # PUT /products/1
  # PUT /products/1.xml
  def update
    @product = Ansuz::NFine::Product.find(params[:id])

    respond_to do |format|
      if @product.update_attributes(params[:product])
        flash[:notice] = 'Ansuz::NFine::Product was successfully updated.'
        format.html { redirect_to(@product) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = Ansuz::NFine::Product.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to(products_url) }
      format.xml  { head :ok }
    end
  end
end
