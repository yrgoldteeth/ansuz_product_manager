module Ansuz
  module NFine
    class CartUserInformation < ActiveRecord::Base

      belongs_to  :user

    end
  end
end

