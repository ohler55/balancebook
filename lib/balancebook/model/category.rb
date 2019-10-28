# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Category

      attr_accessor :id
      attr_accessor :name

      def initialize(id, name)
	@id = id
	@name = name
      end

      def validate(book)
	raise StandardError.new("Category ID can not be empty.") unless !@id.nil? && 0 < @id.size
      end

    end
  end
end
