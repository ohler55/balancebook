# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'balancebook/cmd/report_base'
require 'balancebook/cmd/year_end'
require 'balancebook/cmd/genrow'

module BalanceBook
  module Cmd

    class CurAmount
      attr_accessor :amount
      attr_accessor :base_amount
      attr_accessor :currency

      def initialize(cur)
	@amount = 0.0
	@base_amount = 0.0
	@currency = cur
      end

    end

    class ReportBalance < ReportBase
      extend YearEnd

      def self.help_cmds
	[
	  Help.new('balance', nil, 'balance sheet', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'parens' => 'Parenthesis for negative amounts'
		   }),
	]
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
	parens = hargs.has_key?(:parens)
	money_fmt = parens ? :money : '%.2f'
	money_size = parens ? 11 : 10
	table = Table.new("#{c.name} Balance Sheet #{period.last} in #{cur.upcase}", [
			  Col.new('', -1, :label, nil),
			  Col.new('', money_size, :plus, money_fmt),
			  Col.new('', money_size, :base_plus, money_fmt),
			  Col.new('', money_size, :neg, money_fmt),
			  Col.new('', money_size, :base_neg, money_fmt),
			  ])
	table.add_row(nil)
	assets, receivable = add_assets(table, book, period, cur)
	table.add_row(nil)
	liabilities = add_liabilities(table, book, period, cur)
	table.add_row(nil)
	equity = add_equity(table, book, period, cur)

	table.add_row(nil)
	row = GenRow.new
	row.label = 'Cash Net'
	net = assets - equity
	if 0.0 <= net
	  row.base_plus = net
	else
	  row.base_neg = -net
	end
	row.ansi = BOLD
	table.add_row(row)

	row = GenRow.new
	row.label = 'Accrual Net'
	net = assets + receivable - equity - liabilities
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
	row = GenRow.new
	row.plus = 'Debit'
	row.base_plus = 'Debit ' + cur.upcase
	table.add_row(row)
	table.add_row(Div.new('Assets'))

	total = 0.0
	c.accounts.sort { |a,b| a <=> b }.each { |a|
	  next if Model::Account::FX_LOSS == a.kind
	  row = GenRow.new
	  row.label = "  #{a.name} (#{a.currency})"
	  row.plus = a.balance(period.last)
	  row.base_plus = a.amount_in_currency(book, row.plus, cur, period.last)
	  table.add_row(row)
	  total += row.base_plus
	}
	table.add_row(nil)

	row = GenRow.new
	row.label = '  Cash Total'
	row.base_plus = total
	row.ansi = BOLD
	table.add_row(row)

	table.add_row(nil)
	ar_total = add_receivables_row(table, book, period, cur, true)

	table.add_row(nil)
	row = GenRow.new
	row.label = '  Accrual Total'
	row.base_plus = total + ar_total
	row.ansi = BOLD
	table.add_row(row)

	[total, ar_total]
      end

      def self.add_liabilities(table, book, period, cur)
	c = book.company
	row = GenRow.new
	row.neg = 'Credit'
	row.base_neg = 'Credit ' + cur.upcase
	table.add_row(row)
	table.add_row(Div.new('Liabilities'))

	ap_total = add_payable_row(table, book, period, cur, false)

	table.add_row(nil)
	row = GenRow.new
	row.label = '  Accrual Total'
	row.base_neg = ap_total
	row.ansi = BOLD
	table.add_row(row)

	ap_total
      end

      def self.add_equity(table, book, period, cur)
	c = book.company
	row = GenRow.new
	row.neg = 'Credit'
	row.base_neg = 'Credit ' + cur.upcase
	table.add_row(row)
	table.add_row(Div.new('Equity'))

	base_rate = book.fx.find_rate(cur, period.last)
	eqm = {}
	c.ledger.reverse.each { |e|
	  next unless 'Owner' == e.category
	  d = Date.parse(e.date)
	  next if period.last < d
	  eq = eqm[e.currency]
	  if eq.nil?
	    eq = CurAmount.new(e.currency)
	    eqm[e.currency] = eq
	  end
	  eq.amount += e.amount
	}
	eq_total = 0.0
	eqm.each { |k,eq|
	  row = GenRow.new
	  row.label = "  Owner Equity #{k}"
	  row.neg = eq.amount

	  eq_rate = book.fx.find_rate(eq.currency, period.last)
	  eq.base_amount = (eq.amount / eq_rate).round(2)
	  row.base_neg = eq.base_amount

	  table.add_row(row)
	  eq_total += eq.base_amount
	}
	table.add_row(nil)
	row = GenRow.new
	row.label = '  Total'
	row.base_neg = eq_total
	row.ansi = BOLD
	table.add_row(row)

	eq_total
      end

    end
  end
end
