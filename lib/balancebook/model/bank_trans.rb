# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class BankTrans < Base

      attr_accessor :id
      attr_accessor :credit # boolean
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :who
      attr_accessor :note
      attr_accessor :ledgerTrans

      def validate(book)
	raise StandardError.new("Bank transaction ID can not be empty.") unless !@id.nil? && 0 < @id.size
	validate_date('Transaction date', @date)
	raise StandardError.new("Transaction amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	unless @ledgerTrans.nil?
	  raise StandardError.new("Ledger transaction #{@ledgerTrans} not found.") if book.company.find_trans(@ledgerTrans).nil?
	end
      end

    end
  end
end
