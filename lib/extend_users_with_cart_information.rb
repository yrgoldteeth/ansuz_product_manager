module Ansuz
  module NFine
    module UserExtensions
      def self.included(base)
        base.class_eval do
          has_one :cart_user_information, :class_name => "Ansuz::NFine::CartUserInformation"
          has_many :carts, :class_name => "Ansuz::NFine::Cart"
        end
      end
    end
  end
end

require 'dispatcher'

# This should avoid the problem where methods go missing between reloads
Dispatcher.to_prepare {
  User.send :include, Ansuz::NFine::UserExtensions
}
