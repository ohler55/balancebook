# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transactions
      extend Base

      def self.list(book, args={})
	period = extract_period(book, args)
	name = args[:id]
	acct = book.company.find_account(name)
	raise StandardError.new("Failed to find account #{name}.") if acct.nil?

	table = Table.new("#{acct.name} Transactions (#{acct.currency})", [
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -60, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('ID', -20, :id, nil),
			  ])

	acct.transactions.each { |t|
	  d = Date.parse(t.date)
	  next unless period.in_range(d)
	  table.add_row(t)
	}
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
