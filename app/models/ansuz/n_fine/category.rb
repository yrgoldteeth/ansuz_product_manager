module Ansuz
  module NFine
    class Category < ActiveRecord::Base
      has_and_belongs_to_many :products, :class_name => 'Ansuz::NFine::Product'
    end
  end
end
