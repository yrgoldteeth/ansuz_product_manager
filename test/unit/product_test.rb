require 'test_helper'
require 'factory_girl'

class Ansuz::NFine::ProductTest < ActiveSupport::TestCase

  should_validate_presence_of :name
  should_validate_numericality_of :price
  should_belong_to :category
  should_have_many :quantity_discounts

  context "A product instance with two quantity discounts" do
    setup do
      @first_quantity_discount = Factory.build(:quantity_discount, :low_quantity => 5, :high_quantity => 10, :price => 30.55)
      @second_quantity_discount = Factory.build(:quantity_discount, :low_quantity => 11, :high_quantity => 20, :price => 25.55)
      @category = Factory(:category)
      @product = Factory(:product, :category => @category)
      @product.quantity_discounts = [@first_quantity_discount, @second_quantity_discount]
      @product.save
    end

    context "given a quantity below the minimum quantity discount" do
      setup do
        @result = @product.quantity_price(3)
      end

      should "return the product's base price" do
        assert_equal @product.price, @result
      end
 
    end

    context "given a quantity within the first quantity discount range" do
      setup do
        @result = @product.quantity_price(7)
      end

      should "return the first quantity discount range price" do
        assert_equal @first_quantity_discount.price, @result
      end

    end

    context "given a quantity within the second quantity discount range" do
      setup do
        @result = @product.quantity_price(15)
      end

      should "return the second quantity discount range price" do
        assert_equal @second_quantity_discount.price, @result
      end

    end

    context "given a quantity above the existing discount quantity range" do
      setup do
        @result = @product.quantity_price(50)
      end

      should "return the price of the second discount range price" do
        assert_equal @product.maximum_discount_price, @result
      end

    end

  end
end
