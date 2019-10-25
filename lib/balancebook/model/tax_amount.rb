# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class TaxAmount

      attr_accessor :tax
      attr_accessor :amount

      def initialize(tax, amount)
	@tax = tax
	@amount = amount
      end

    end
  end
end
