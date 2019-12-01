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
	tsv = args.has_key?(:tsv)
	csv = args.has_key?(:csv)
	method = args[:method]
	method = 'cash' if method.nil?

	# TBD method=cash|accrual
	#  if accrual then add in outstanding invoices
	# TBD get currency
	# TBD filter params like status, category, etc

	table = Table.new("Balances (#{first} to #{last}) #{method} method", [
			  Col.new('Account', -20, :label, nil),
			  Col.new('Cur', 3, :currency, nil),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new("Balance #{cur}", 11, :base_balance, '%.2f'),
			  ])

	balances = []

	# loop through transactions first then through transfers to bring up
	# to date.
	book.company.accounts.each { |a|
	  b = Balance.new(a, a.name, a.currency)
	  balances << b

	  a.transactions.each { |t|
	    date = Date.parse(t.date)
	    next if date < first || last < date
	    b.balance += t.amount
	    b.base_balance += a.amount_in_currency(book, t.amount, cur, t.date)
	  }
	}

	book.company.transfers.each { |t|
	  date = Date.parse(t.date)
	  next if date < first || last < date
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

	  from.base_balance -= from.account.amount_in_currency(book, t.sent, cur, t.date)
	  to.base_balance += to.account.amount_in_currency(book, t.sent, cur, t.date)
	}

	ledger = Balance.new(nil, 'Ledger', cur)
	balances << ledger
	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next if date < first || last < date
	  ledger.balance += e.amount_in_currency(book, cur)
	}
	if method.downcase == 'accrual'
	  book.company.invoices.each { |inv|
	    date = Date.parse(inv.submitted)
	    next if date < first || last < date

	    # TBD remove payment from invoice before
	    # for invoices submitted before first and paid this period should have payments subtracted

	    paid_by = inv.amount - inv.paid_amount_by(last)
	    next if paid_by == 0
	    ledger.balance += amount_in_currency(book, inv.amount, inv.currency, cur, inv.submitted)
	  }
	end
	ledger.base_balance = ledger.balance

	total = 0.0
	cash = 0.0
	balances.each { |b|
	  unless b.account.nil?
	    total += b.base_balance
	    cash += b.base_balance if Model::Account::CASH == b.account.kind
	  end
	  table.add_row(b)
	}
	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display
	  puts "Account Total                           %10.2f" % [total]
	  puts "Cash Balance                            %10.2f" % [cash]
	  puts
	end
      end

      def self.amount_in_currency(book, amount, cur, base_cur, date)
	return amount if cur == base_cur
	base_rate = book.fx.find_rate(base_cur, date)
	src_rate = book.fx.find_rate(cur, date)
	amount * base_rate / src_rate
      end

    end
  end
end
