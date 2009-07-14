require 'test_helper'
require 'factory_girl'

class Ansuz::NFine::CategoryTest < ActiveSupport::TestCase

  should_validate_presence_of :name
  should_have_many :products
  should_have_many :quantity_discounts

end
