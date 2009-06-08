module Ansuz
  module NFine
    class LineItem < ActiveRecord::Base

      belongs_to  :cart, :class_name => 'Ansuz::NFine::Cart'
      has_one  :product, :class_name => 'Ansuz::NFine::Product'
#      has_attached_file  :attachment #TODO add relevant stuff for paperclip attaching to line items

    end
  end
end

