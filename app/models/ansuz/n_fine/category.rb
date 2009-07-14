module Ansuz
  module NFine
    class Category < ActiveRecord::Base
      has_many :products, :class_name => 'Ansuz::NFine::Product'
      has_many :quantity_discounts, :class_name => 'Ansuz::NFine::QuantityDiscount', :through => :products
      validates_presence_of :name
    end
  end
end
