# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Tax

      attr_accessor :id
      attr_accessor :name
      attr_accessor :percent

      def initialize(id, name, percent)
	@id = id
	@name = name
	@percent = percent
      end

    end
  end
end
