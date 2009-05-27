module Ansuz
  module NDFine
    class QuantityDiscount < ActiveRecord::Base
      belongs_to  :product

      def quantity_range
        self.low_quantity.to_s + " - " + self.high_quantity.to_s
      end

    end
  end
end
