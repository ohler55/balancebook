# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Model

    class Transaction < Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :who
      attr_accessor :ledger_tx # a list to support split ledger entries, 0 is bank error
      attr_accessor :_account
      attr_accessor :_ledger_date

      def initialize(id, date, amount, who)
	@id = id
	@date = date
	@amount = amount
	@who = who
      end

      def prepare(book, acct)
	@_account = acct
	unless @ledger_tx.nil?
	  if @ledger_tx.is_a?(Array)
	    @ledger_tx.each { |tx|
	      lx = book.company.find_entry(tx)
	      raise StandardError.new("Ledger transaction #{tx} not found.") if lx.nil?
	      @_ledger_date = Date.parse(lx.date)
	      break
	    }
	  elsif 0 != @ledger_tx
	    lx = book.company.find_entry(@ledger_tx)
	    raise StandardError.new("Ledger transaction #{@ledger_tx} not found.") if lx.nil?
	      @_ledger_date = Date.parse(lx.date)
	  end
	end
      end

      def validate(book)
	raise StandardError.new("Bank transaction ID can not be empty.") unless !@id.nil? && 0 < @id.size
	validate_date('Transaction date', @date)
	unless @ledger_tx.nil?
	  if @ledger_tx.is_a?(Array)
	    @ledger_tx.each { |tx|
	      raise StandardError.new("Ledger transaction #{tx} not found.") if book.company.find_entry(tx).nil?
	    }
	  elsif 0 != @ledger_tx
	    raise StandardError.new("Ledger transaction #{@ledger_tx} not found.") if book.company.find_entry(@ledger_tx).nil?
	  end
	end
      end

    end
  end
end
