require 'test_helper'
require 'factory_girl'

class Ansuz::NFine::QuantityDiscountTest < ActiveSupport::TestCase

  should_belong_to :product
  should_validate_presence_of :price, :low_quantity, :high_quantity

end
