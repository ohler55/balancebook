# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Payment < Base

      attr_accessor :account
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :note

      def validate(book)
	raise StandardError.new("Invoice amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	validate_date('Payment date', @date)
	acct = book.company.find_account(@account)
	raise StandardError.new("Payment account #{@account} not found.") if acct.nil?
      end

    end
  end
end
