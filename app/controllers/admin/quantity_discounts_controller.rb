class QuantityDiscountsController < ApplicationController
  # GET /quantity_discounts
  # GET /quantity_discounts.xml
  def index
    @quantity_discounts = QuantityDiscount.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @quantity_discounts }
    end
  end

  # GET /quantity_discounts/1
  # GET /quantity_discounts/1.xml
  def show
    @quantity_discount = QuantityDiscount.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quantity_discount }
    end
  end

  # GET /quantity_discounts/new
  # GET /quantity_discounts/new.xml
  def new
    @quantity_discount = QuantityDiscount.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quantity_discount }
    end
  end

  # GET /quantity_discounts/1/edit
  def edit
    @quantity_discount = QuantityDiscount.find(params[:id])
  end

  # POST /quantity_discounts
  # POST /quantity_discounts.xml
  def create
    @quantity_discount = QuantityDiscount.new(params[:quantity_discount])

    respond_to do |format|
      if @quantity_discount.save
        flash[:notice] = 'QuantityDiscount was successfully created.'
        format.html { redirect_to(@quantity_discount) }
        format.xml  { render :xml => @quantity_discount, :status => :created, :location => @quantity_discount }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quantity_discount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quantity_discounts/1
  # PUT /quantity_discounts/1.xml
  def update
    @quantity_discount = QuantityDiscount.find(params[:id])

    respond_to do |format|
      if @quantity_discount.update_attributes(params[:quantity_discount])
        @product = Product.find(@quantity_discount.product_id)
        flash[:notice] = 'QuantityDiscount was successfully updated.'
        format.html { redirect_to(@product) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quantity_discount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quantity_discounts/1
  # DELETE /quantity_discounts/1.xml
  def destroy
    @quantity_discount = QuantityDiscount.find(params[:id])
    @quantity_discount.destroy

    respond_to do |format|
      format.html { redirect_to(quantity_discounts_url) }
      format.xml  { head :ok }
    end
  end
end
