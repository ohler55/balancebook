# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Transaction < Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :who
      attr_accessor :ledger_tx # a list to support split ledger entries
      attr_accessor :_account

      def initialize(id, date, amount, who)
	@id = id
	@date = date
	@amount = amount
	@who = who
      end

      def prepare(book, acct)
	@_account = acct
      end

      def validate(book)
	raise StandardError.new("Bank transaction ID can not be empty.") unless !@id.nil? && 0 < @id.size
	validate_date('Transaction date', @date)
	unless @ledger_tx.nil?
	  raise StandardError.new("Ledger transaction #{@ledger_tx} not found.") if book.company.find_entry(@ledger_tx).nil?
	end
      end

    end
  end
end
