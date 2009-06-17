module Ansuz
  module NFine
    class Address < ActiveRecord::Base

      belongs_to  :person, :class_name => 'Ansuz::NFine::Person'
      belongs_to  :cart, :class_name => 'Ansuz::NFine::Cart'

    end
  end
end

