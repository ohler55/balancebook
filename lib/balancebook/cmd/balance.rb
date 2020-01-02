# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class Balance
      extend Base

      attr_accessor :account
      attr_accessor :label
      attr_accessor :balance
      attr_accessor :base_balance
      attr_accessor :currency
      attr_accessor :base_sum

      def initialize(acct=nil, label=nil, currency=nil)
	@account = acct
	@label = label
	@currency = currency
	unless currency == nil
	  @balance = 0.0
	  @base_balance = 0.0
	  @base_sum = 0.0
	end
      end

      def self.report(book, args={})
	period = extract_period(book, args)
	tsv = args.has_key?(:tsv)
	csv = args.has_key?(:csv)
	method = args[:method] # cash or accrual
	method = 'cash' if method.nil?
	cur = args[:currency]
	cur = book.fx.base if cur.nil?

	table = Table.new("Balances (#{period.first} to #{period.last}) #{method} method", [
			  Col.new('Account', -20, :label, nil),
			  Col.new('Cur', 3, :currency, nil),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new("Balance #{cur}", 11, :base_balance, '%.2f'),
			  Col.new("Sum #{cur}", 11, :base_sum, '%.2f'),
			  ])
	balances = []

	# loop through transactions first then through transfers to bring up
	# to date.
	book.company.accounts.each { |a|
	  b = Balance.new(a, a.name, a.currency)
	  b.base_sum = a.sum_in_currency(book, cur, period, nil, true)
	  balances << b
	}
	add_transactions(book, balances, cur, period)

	# TBD Already covered by transactions. Could add fx loss though
	#add_transfers(book, balances, cur, period)

	ledger = Balance.new(nil, 'Ledger', cur)
	balances << ledger
	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next unless period.in_range(date)
	  ledger.balance += e.amount_in_currency(book, cur)
	}
	accrual_adjust(book, ledger, cur, period) if method.downcase == 'accrual'
	ledger.base_balance = ledger.balance
	ledger.base_sum = ledger.balance

	total = 0.0
	cash = 0.0
	sum = 0.0
	balances.each { |b|
	  unless b.account.nil?
	    total += b.base_balance.round(2)
	    cash += b.base_balance.round(2) if Model::Account::CASH == b.account.kind
	    sum += b.base_sum
	  end
	  table.add_row(b)
	}
	table.add_row(Balance.new)

	b = Balance.new(nil, "Account Total", nil)
	b.base_balance = total
	b.base_sum = sum
	table.add_row(b)

	b = Balance.new(nil, "Cash Balance", nil)
	b.base_balance = cash
	table.add_row(b)

	b = Balance.new(nil, "Ledger - Account", nil)
	b.base_sum = ledger.base_sum - sum
	table.add_row(b)

	case args[:format] || args[:fmt]
	when 'tsv'
	  table.tsv
	when 'csv'
	  table.csv
	else
	  table.display
	end
      end

      def self.amount_in_currency(book, amount, cur, base_cur, date)
	return amount if cur == base_cur
	base_rate = book.fx.find_rate(base_cur, date)
	src_rate = book.fx.find_rate(cur, date)
	(amount * base_rate / src_rate).round(2)
      end

      def self.add_transactions(book, balances, cur, period)
	balances.each { |b|
	  b.account.transactions.each { |t|
	    date = Date.parse(t.date)
	    next unless period.in_range(date)
	    b.balance += t.amount
	  }
	  b.base_balance = b.account.amount_in_currency(book, b.balance, cur, period.last).round(2)
	}
      end

      def self.add_transfers(book, balances, cur, period)
	book.company.transfers.each { |t|
	  date = Date.parse(t.date)
	  next unless period.in_range(date)
	  from = nil
	  to = nil
	  balances.each { |b|
	    if b.account.id == t.from
	      from = b
	    elsif b.account.id == t.to
	      to = b
	    end
	  }
	  from.balance -= t.sent
	  to.balance += t.received

	  from.base_balance -= from.account.amount_in_currency(book, t.sent, cur, t.date).round(2)
	  to.base_balance += to.account.amount_in_currency(book, t.sent, cur, t.date).round(2)
	}
      end

      def self.accrual_adjust(book, ledger, cur, period)
	book.company.invoices.each { |inv|
	  submitted = Date.parse(inv.submitted)
	  pd = inv.paid_date
	  next if period.last < submitted
	  if submitted < period.first
	    ledger.balance -= inv.paid if period.first <= pd && pd <= period.last
	    next
	  end
	  paid_by = inv.amount - inv.paid_amount_by(period.last)
	  next if paid_by == 0
	  ledger.balance += amount_in_currency(book, inv.amount, inv.currency, cur, inv.submitted).round(2)
	}
      end

    end
  end
end
