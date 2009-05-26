class Admin::ProductsController < Admin::BaseController
  # GET /products
  # GET /products.xml
  def index
    @products = Ansuz::Product.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @product = Ansuz::Product.find(params[:id])
    @quantity_discounts = @product.quantity_discounts

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/new
  # GET /products/new.xml
  def new
    @product = Ansuz::Product.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/1/edit
  def edit
    @product = Ansuz::Product.find(params[:id])
  end

  # POST /products
  # POST /products.xml
  def create
    @product = Ansuz::Product.new(params[:product])

    respond_to do |format|
      if @product.save
        flash[:notice] = 'Ansuz::Product was successfully created.'
        format.html { redirect_to(@product) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create_quantity_discount
    @product = Ansuz::Product.find(params[:id])
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
    @product = Ansuz::Product.find(params[:id])

    respond_to do |format|
      if @product.update_attributes(params[:product])
        flash[:notice] = 'Ansuz::Product was successfully updated.'
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
    @product = Ansuz::Product.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to(products_url) }
      format.xml  { head :ok }
    end
  end
end
