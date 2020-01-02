# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Entry < Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :amount
      attr_accessor :who
      attr_accessor :account
      attr_accessor :category
      attr_accessor :taxes # TaxAmount array
      attr_accessor :tip # no tax unless part of bill
      attr_accessor :acct_tx
      attr_accessor :file
      attr_accessor :note
      attr_accessor :_account

      def initialize(id)
	@id = id # generated by company to be unique
      end

      def prepare(book, company)
	@_account = company.find_account(@account)
	# TBD  date
      end

      def tax(kind=nil)
	return 0.0 if @taxes.nil?
	sum = 0.0
	@taxes.each { |ta| sum += ta.amount if kind.nil? || kind == ta.tax }
	sum.round(2)
      end

      def amount_in_currency(book, base_cur)
	acct = book.company.find_account(@account)
	raise StandardError.new("Account #{@account} not found.") if acct.nil?
	return @amount if acct.currency == base_cur
	base_rate = book.fx.find_rate(base_cur, @date)
	acct_rate = book.fx.find_rate(acct.currency, @date)
	(@amount * base_rate / acct_rate).round(2)
      end

      def validate(book)
	raise StandardError.new("Entry ID can not be empty.") unless !@id.nil? && 0 < @id
	validate_date('Entry date', @date)
	acct = book.company.find_account(@account)
	raise StandardError.new("Entry account #{@account} not found.") if acct.nil?
	cat = book.company.find_category(@category)
	raise StandardError.new("Entry category #{@category} not found.") if cat.nil?
	unless @acct_tx.nil?
	  raise StandardError.new("Account transaction #{@account}:#{@acct_tx} not found.") if '-' != @acct_tx && acct.find_trans(@acct_tx).nil?
	end
      end

    end
  end
end
