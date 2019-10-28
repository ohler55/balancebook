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

      def validate(book)
	raise StandardError.new("Tax Amount tax of #{@tax} not found.") if book.company.find_tax(@tax)
	raise StandardError.new("Tax amount of #{@amount} must be greater than or equal to 0.0.") unless 0.0 <= @amount
      end

    end
  end
end
