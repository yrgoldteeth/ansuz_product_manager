module Ansuz
  module NDFine
    class Product < ActiveRecord::Base
      has_and_belongs_to_many :categories
      has_many  :quantity_discounts, :dependent => :destroy
      validates_presence_of  :name

      def minimum_discount_quantity
        product_quantity_discounts = self.quantity_discounts
        minimum_quantity = []
        product_quantity_discounts.each do |q|
          minimum_quantity << q.low_quantity
        end
        return minimum_quantity.sort[0]
      end

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
