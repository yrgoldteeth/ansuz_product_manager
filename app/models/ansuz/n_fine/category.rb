module Ansuz
  module NFine
    class Category < ActiveRecord::Base
      has_many :products, :class_name => 'Ansuz::NFine::Product'
    end
  end
end
