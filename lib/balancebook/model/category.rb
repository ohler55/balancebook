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

    end
  end
end
