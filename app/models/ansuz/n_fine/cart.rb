module Ansuz
  module NFine
    class Cart < ActiveRecord::Base

      belongs_to  :user
      has_many  :line_items,  :class_name => 'Ansuz::NFine::LineItem', :dependent => :destroy
      has_many  :products, :through => :line_items

      def ordered?
        ordered_at ? true : false
      end
    end
  end
end
