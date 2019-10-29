# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Transaction < Base

      attr_accessor :id
      attr_accessor :credit # boolean
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :who
      attr_accessor :account
      attr_accessor :category
      attr_accessor :tax
      attr_accessor :acctTrans
      attr_accessor :file
      attr_accessor :note

      def validate(book)
	raise StandardError.new("Transaction ID can not be empty.") unless !@id.nil? && 0 < @id.size
	validate_date('Transaction date', @date)
	raise StandardError.new("Transaction amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	acct = book.company.find_account(@account).nil?
	raise StandardError.new("Transaction account #{@account} not found.") if acct.nil?
	unless @acctTrans.nil?
	  raise StandardError.new("Account transaction #{@account}-#{@acctTrans} not found.") if acct.find_trans(@acctTrans).nil?
	end
      end

    end
  end
end
