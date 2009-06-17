module Ansuz
  module NFine
    class Cart < ActiveRecord::Base

      belongs_to  :user
      has_one  :person, :class_name => 'Ansuz::NFine::Person'
      has_many  :line_items,  :class_name => 'Ansuz::NFine::LineItem', :dependent => :destroy
      has_many  :products, :through => :line_items

      before_save  :update_subtotal, :update_total

      def ordered?
        ordered_at ? true : false
      end

      def add product, options = {}
        options = { :quantity => 1 }.merge(options)
        options[:cart_id] = self.id
        li = Ansuz::NFine::LineItem.new(options)
        li.product = product
        li.calculate_total
        li.save
      end

      def total_in_cents
        (total * 100).to_i if total
      end

      def calculated_subtotal
        calc = line_items.inject(0.0) do |sum, li|
          sum += li.amount
        end
        calc.nil? ? 0.0.to_d : calc
      end

      def update_subtotal
        self.subtotal = calculated_subtotal
      end

      def update_subtotal!
        update_subtotal
        save
      end

      def calculated_total
        begin
          subtotal + shipping_rate + rush_rate + sales_tax
        rescue
          subtotal
        end
      end

      def update_total
        self.total = calculated_total if (status != 'canceled')
      end

      def update_total!
        update_total
        save
      end

      def proper_person
        if user
          user.person
        else
          person
        end
      end

    end
  end
end
