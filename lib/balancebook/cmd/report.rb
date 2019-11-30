# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'balancebook/cmd/balance'

module BalanceBook
  module Cmd

    class Report
      extend Base

      def self.balance(book, args={})
	first, last = extract_date_range(book, args)
	cur = book.fx.base

	# TBD get currency
	# TBD filter params like status, category, etc

	table = Table.new("Balances (#{first} to #{last})", [
			  Col.new(' ', -20, :label, nil),
			  Col.new('Cur', 3, :currency, nil),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new("Balance #{cur}", 11, :base_balance, '%.2f'),
			  ])

	balances = []

	ledger = Balance.new('Ledger', cur)
	balances << ledger
	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next if date < first || last < date
	  ledger.balance += e.amount_in_currency(book, cur)
	}
	ledger.base_balance = ledger.balance

	book.company.accounts.each { |a|
	  b = Balance.new(a.name, a.currency)
	  balances << b

	  a.transactions.each { |t|
	    date = Date.parse(t.date)
	    next if date < first || last < date
	    b.balance += t.amount
	    b.base_balance += a.amount_in_currency(book, t.amount, cur, t.date)
	  }
	}
	total = 0.0
	balances.each { |t|
	  table.add_row(t)
	  total += t.base_balance
	}
	table.display
	puts "Total                                   %10.2f" % [total]
	puts
      end

    end
  end
end
