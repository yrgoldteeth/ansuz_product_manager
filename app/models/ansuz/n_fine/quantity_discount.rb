module Ansuz
  module NFine
    class QuantityDiscount < ActiveRecord::Base
      belongs_to  :product, :class_name => 'Ansuz::NFine::Product'

      def quantity_range
        self.low_quantity.to_s + " - " + self.high_quantity.to_s
      end

    end
  end
end
