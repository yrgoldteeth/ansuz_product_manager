module Ansuz
  module NFine
    class Person < ActiveRecord::Base

      belongs_to  :cart, :class_name => 'Ansuz::NFine::Cart'
      belongs_to  :user
      has_many  :addresses, :class_name => 'Ansuz::NFine::Address', :order => 'id DESC'

    end
  end
end

