# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

require 'balancebook/cmd/report_base'

module BalanceBook
  module Cmd

    class CurAmount
      attr_accessor :amount
      attr_accessor :base_amount

      def initialize
	@amount = 0.0
	@base_amount = 0.0
      end

    end

    class ReportBalance < ReportBase

      attr_accessor :title
      attr_accessor :label
      attr_accessor :plus
      attr_accessor :base_plus
      attr_accessor :neg
      attr_accessor :base_neg
      attr_accessor :ansi

      def initialize
      end

      def self.report(book, args, hargs)
	c = book.company
	period = extract_period(book, hargs)
	tsv = hargs.has_key?(:tsv)
	csv = hargs.has_key?(:csv)
	cur = book.fx.base
	if hargs.has_key?(:currency)
	  cur = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	end
	table = Table.new("#{c.name} Balance Sheet #{period.last} in #{cur}", [
			  Col.new('', -1, :label, nil),
			  Col.new('', 10, :plus, '%.2f'),
			  Col.new('', 10, :base_plus, '%.2f'),
			  Col.new('', 10, :neg, '%.2f'),
			  Col.new('', 10, :base_neg, '%.2f'),
			  ])
	table.add_row(nil)
	assets = add_assets(table, book, period, cur)
	table.add_row(nil)
	add_liabilities(table, book, period, cur)
	table.add_row(nil)
	equity = add_equity(table, book, period, cur)

	table.add_row(nil)
	row = new
	row.label = '  Cash Net'
	net = assets - equity
	if 0.0 <= net
	  row.base_plus = net
	else
	  row.base_neg = -net
	end
	row.ansi = BOLD
	table.add_row(row)

	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display(false)
	end
      end

      def self.add_assets(table, book, period, cur)
	c = book.company
	row = new
	row.base_plus = cur
	table.add_row(row)
	table.add_row(Div.new('Assets'))

	total = 0.0
	c.accounts.sort { |a,b| a <=> b }.each { |a|
	  next if Model::Account::FX_LOSS == a.kind
	  row = new
	  row.label = "  #{a.name} (#{a.currency})"
	  row.plus = a.balance(period.last)
	  row.base_plus = a.amount_in_currency(book, row.plus, cur, period.last)
	  table.add_row(row)
	  total += row.base_plus
	}
	table.add_row(nil)

	row = new
	row.label = '  Cash Total'
	row.base_plus = total
	row.ansi = BOLD
	table.add_row(row)

	table.add_row(nil)

	base_rate = book.fx.find_rate(cur, period.last)
	arm = {}
	c.invoices.each { |inv|
	  d = Date.parse(inv.submitted)
	  next if period.last < d
	  out = inv.amount - inv.paid_amount_by(period.last)
	  next if out <= 0.0
	  ar = arm[inv.currency]
	  if ar.nil?
	    ar = CurAmount.new
	    arm[inv.currency] = ar
	  end
	  inv_rate = book.fx.find_rate(inv.currency, period.last)
	  ar.amount += out
	  ar.base_amount += (out * base_rate / inv_rate).round(2)
	}
	ar_total = 0.0
	arm.each { |k,ar|
	  row = new
	  row.label = "  Accounts Receivable #{k}"
	  row.plus = ar.amount
	  row.base_plus = ar.base_amount
	  table.add_row(row)
	  ar_total += ar.base_amount
	}

	table.add_row(nil)
	row = new
	row.label = '  Accrual Total'
	row.base_plus = total + ar_total
	row.ansi = BOLD
	table.add_row(row)

	total
      end

      def self.add_liabilities(table, book, period, cur)
	c = book.company
	row = new
	row.base_neg = cur
	table.add_row(row)
	table.add_row(Div.new('Liabilities'))

	ap_total = 0.0
	base_rate = book.fx.find_rate(cur, period.last)
	apm = {}
	c.bills.each { |bill|
	  d = Date.parse(bill.received)
	  next if period.last < d
	  out = bill.amount - bill.paid_amount_by(period.last)
	  next if out <= 0.0
	  ap = apm[bill.currency]
	  if ap.nil?
	    ap = CurAmount.new
	    apm[bill.currency] = ap
	  end
	  bill_rate = book.fx.find_rate(bill.currency, period.last)
	  ap.amount += out
	  ap.base_amount += (out * base_rate / bill_rate).round(2)
	}
	apm.each { |k,ap|
	  row = new
	  row.label = "  Accounts Payable #{k}"
	  row.neg = ap.amount
	  row.base_neg = ap.base_amount
	  table.add_row(row)
	  ap_total += ap.base_amount
	}

	# TBD also per diem not paid in the future

	table.add_row(nil)
	row = new
	row.label = '  Accrual Total'
	row.base_neg = ap_total
	row.ansi = BOLD
	table.add_row(row)

	ap_total
      end

      def self.add_equity(table, book, period, cur)
	c = book.company
	row = new
	row.base_neg = cur
	table.add_row(row)
	table.add_row(Div.new('Equity'))

	total = 0.0
	base_rate = book.fx.find_rate(cur, period.last)
	eqm = {}
	c.ledger.each { |e|
	  next unless 'Owner' == e.category
	  d = Date.parse(e.date)
	  next if period.last < d
	  eq = eqm[e.currency]
	  if eq.nil?
	    eq = CurAmount.new
	    eqm[e.currency] = eq
	  end
	  eq_rate = book.fx.find_rate(e.currency, period.last)
	  eq.amount += e.amount
	  eq.base_amount += (e.amount * base_rate / eq_rate).round(2)
	}
	eq_total = 0.0
	eqm.each { |k,eq|
	  row = new
	  row.label = "  Owner Equity #{k}"
	  row.neg = eq.amount
	  row.base_neg = eq.base_amount
	  table.add_row(row)
	  eq_total += eq.base_amount
	}
	table.add_row(nil)
	row = new
	row.label = '  Total'
	row.base_neg = eq_total
	row.ansi = BOLD
	table.add_row(row)

	eq_total
      end

    end
  end
end
