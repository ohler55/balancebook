# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Person

      attr_accessor :name
      attr_accessor :role
      attr_accessor :email
      attr_accessor :phone

      def initialize(name)
	@name = name
      end

    end
  end
end
