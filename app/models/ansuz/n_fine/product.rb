module Ansuz
  module NFine
    class Product < ActiveRecord::Base
      belongs_to :category, :class_name => 'Ansuz::NFine::Category'
      has_many  :quantity_discounts, :class_name => 'Ansuz::NFine::QuantityDiscount', :dependent => :destroy
      has_attached_file  :image
      validates_presence_of  :name

      #creates a range for the low and high end of product's existing quantity discounts
      def existing_discount_quantity_range
        product_quantity_discounts = self.quantity_discounts
        minimum_quantity = []
        maximum_quantity = []
        product_quantity_discounts.each do |q|
          minimum_quantity << q.low_quantity
          maximum_quantity << q.high_quantity
        end
        return minimum_quantity.sort.first..maximum_quantity.sort.last
      end
      
      #returns product's price for a given quantity
      def quantity_price (quantity)
        if self.has_quantity_discount? && self.minimum_discount_quantity < quantity
          product_quantity_discounts = self.quantity_discounts
          product_quantity_discounts.each do |q|
            quantity_range = q.low_quantity..q.high_quantity
            if quantity_range.include?(quantity)
              return q.price
            end
          end
        else
          return self.price
        end
      end

      def has_quantity_discount!
        self.has_quantity_discount = true
      end

    end
  end
end
