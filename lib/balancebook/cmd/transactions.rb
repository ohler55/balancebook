# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transactions
      extend Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :who
      attr_accessor :amount
      attr_accessor :balance
      attr_accessor :ledger_tx

      def initialize(tx=nil, balance=nil)
	unless tx.nil?
	  @id = tx.id
	  @date = tx.date
	  @who = tx.who
	  @amount = tx.amount
	  @ledger_tx = tx.ledger_tx
	end
	@balance = balance
      end

      def self.list(book, args, hargs={})
	period = extract_period(book, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.accounts.map { |a| a.id } + c.accounts.map { |a| a.name })
	acct = book.company.find_account(id)
	raise StandardError.new("Failed to find account #{id}.") if acct.nil?

	table = Table.new("#{acct.name} Transactions (#{acct.currency})", [
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -1, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new('ID', -1, :id, nil),
			  Col.new('Ledger', -1, :ledger_tx, nil),
			  ])
	total = 0.0
	acct.transactions.reverse.each { |t|
	  d = Date.parse(t.date)
	  next unless period.in_range(d)
	  total += t.amount
	  table.add_row(new(t, total))
	}
	table.add_row(new)
	tx = new(nil, total)
	tx.who = 'Total'
	table.add_row(new(nil, total))
	table.display
      end

      def self.create(book, args)
	puts "\nEnter information for a new Bank Tranaction"
	aid = args[:account] || read_str('Account')
	acct = book.company.find_account(aid)
	raise StandardError.new("Failed to find account #{name}.") if acct.nil?
	id = args[:id] || read_str('ID')
	date = args[:date] || read_str('Date')
	amount = (args[:amount] || read_amount('Amount')).to_f
	who = args[:who] || read_str('Description')
	model = Model::Transaction.new(id, date, amount, who)
	model.validate(book)
	acct.add_trans(model)
	model
      end

    end
  end
end
