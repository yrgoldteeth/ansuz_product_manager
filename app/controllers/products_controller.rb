class ProductsController < Admin::BaseController #TODO fix this class inheritance to not inherit the admin controller.  fucking duh.
  unloadable # This is required if you subclass a controller provided by the base rails app
  before_filter :load_product,     :only => [:show] 
  before_filter :load_products,    :only => [:index]

  protected
  def load_product
    @product = Ansuz::NFine::Product.find(params[:id], :include => [:quantity_discounts, :category])
  end

  def load_products
#    @products = Ansuz::NFine::Product.find(:all, :order => 'created_at DESC')
    @categories = Ansuz::NFine::Category.find(:all, :include => [:products, :quantity_discounts])
  end

  public #TODO for reals.  put a format do statement like in the blog plugin.  
  def index
  end

  def show
  end

end
