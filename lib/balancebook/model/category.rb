# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Category

      attr_accessor :name
      attr_accessor :expense

      def initialize(name)
	@name = name
      end

      alias :id :name

      def validate(book)
	raise StandardError.new("Category name can not be empty.") unless !@name.nil? && 0 < @name.size
      end

    end
  end
end
