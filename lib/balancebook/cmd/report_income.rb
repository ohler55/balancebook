# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'balancebook/cmd/report_base'
require 'balancebook/cmd/year_end'
require 'balancebook/cmd/genrow'

module BalanceBook
  module Cmd

    class ReportIncome < ReportBase
      extend YearEnd

      class Cur
	attr_accessor :id
	attr_accessor :amount
	attr_accessor :base_amount

	def initialize(id)
	  @id = id
	  @amount = 0.0
	  @base_amount = 0.0
	end
      end

      class Cat
	attr_accessor :id
	attr_accessor :curs
	attr_accessor :expense

	def initialize(book, id)
	  @id = id
	  @curs = {}
	  cat = book.company.find_category(id)
	  if cat.nil?
	    @expense = true
	  else
	    @expense = cat.expense
	  end
	end

	def add(e, book, cur)
	  c = @curs[e.currency]
	  if c.nil?
	    c = Cur.new(e.currency)
	    @curs[c.id] = c
	  end
	  c.amount += e.amount
	  c.base_amount += e.amount_in_currency(book, cur)
	end

	def add_tx(amount, tx_cur, base_amount)
	  c = @curs[tx_cur]
	  if c.nil?
	    c = Cur.new(tx_cur)
	    @curs[c.id] = c
	  end
	  c.amount += amount
	  c.base_amount += base_amount
	end

	def empty?
	  @curs.each_value { |c|
	    return false if 0.0 != c.base_amount.round(2)
	  }
	  true
	end

      end

      def self.help_cmds
	[
	  Help.new('income', nil, 'income statement', {
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
	rev = hargs.has_key?(:reverse)
	cur = book.fx.base
	if hargs.has_key?(:currency)
	  cur = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	end
	parens = hargs.has_key?(:parens)
	money_fmt = parens ? :money : '%.2f'
	money_size = parens ? 11 : 10
	table = Table.new("#{c.name} Income Statement from #{period.first} to #{period.last} in #{cur}", [
			    Col.new('', -1, :label, nil),
			    Col.new('', money_size, :plus, money_fmt),
			    Col.new('', money_size, :base_plus, money_fmt),
			    Col.new('', money_size, :neg, money_fmt),
			    Col.new('', money_size, :base_neg, money_fmt),
			  ])

	cats = by_cat(book, period, cur)

	table.add_row(nil)
	revenue, ar = add_revenue(table, cats, book, period, cur)
	table.add_row(nil)
	expenses, ap = add_expenses(table, cats, book, period, cur)
	table.add_row(nil)

	row = GenRow.new
	row.label = 'Cash Net Income'
	row.base_neg = revenue - expenses
	row.ansi = BOLD
	table.add_row(row)

	row = GenRow.new
	row.label = 'Accrual Net Income'
	row.base_neg = revenue + ar - expenses - ap
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

      def self.add_revenue(table, cats, book, period, cur)
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	row = GenRow.new
	row.base_plus = cur
	row.base_neg = cur
	table.add_row(row)
	table.add_row(Div.new('Revenue'))

	total = 0.0
	cats.keys.sort.each { |k|
	  cat = cats[k]
	  next unless false == cat.expense
	  next if cat.empty?
	  if 1 < cat.curs.size
	    row = GenRow.new
	    row.label = "  #{cat.id}"
	    table.add_row(row)

	    cat.curs.each { |_,c|
	      row = GenRow.new
	      row.label = "    #{c.id}"
	      row.neg = c.amount
	      row.base_neg = c.base_amount
	      table.add_row(row)
	      total += c.base_amount
	    }
	  else
	    c = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{c.id})"
	    row.neg = c.amount
	    row.base_neg = c.base_amount
	    table.add_row(row)
	    total += c.base_amount
	  end
	}
	table.add_row(nil)
	row = GenRow.new
	row.label = '  Cash Total'
	row.base_neg = total
	row.ansi = BOLD
	table.add_row(row)

	table.add_row(nil)
	ar_total = add_receivables_row(table, book, period, cur, false)

	table.add_row(nil)
	row = GenRow.new
	row.label = '  Accrual Total'
	row.base_neg = total + ar_total
	row.ansi = BOLD
	table.add_row(row)

	[total, ar_total]
      end

      def self.add_expenses(table, cats, book, period, cur)
	c = book.company
	row = GenRow.new
	row.base_plus = cur
	row.base_neg = cur
	table.add_row(row)
	table.add_row(Div.new('Expenses'))

	total = 0.0
	cats.keys.sort.each { |k|
	  cat = cats[k]
	  next unless true == cat.expense
	  next if cat.empty?
	  if 1 < cat.curs.size
	    row = GenRow.new
	    row.label = "  #{cat.id}"
	    table.add_row(row)

	    cat.curs.each { |_,c|
	      row = GenRow.new
	      row.label = "    #{c.id}"
	      row.plus = -c.amount
	      row.base_plus = -c.base_amount
	      table.add_row(row)
	      total -= c.base_amount
	    }
	  else
	    c = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{c.id})"
	    row.plus = -c.amount
	    row.base_plus = -c.base_amount
	    table.add_row(row)
	    total -= c.base_amount
	  end
	}
	table.add_row(nil)
	row = GenRow.new
	row.label = '  Cash Total'
	row.base_plus = total
	row.ansi = BOLD
	table.add_row(row)

	table.add_row(nil)
	ap_total = add_payable_row(table, book, period, cur, true)


	table.add_row(nil)
	row = GenRow.new
	row.label = '  Accrual Total'
	row.base_plus = total + ap_total
	row.ansi = BOLD
	table.add_row(row)

	[total, ap_total]
      end

      def self.by_cat(book, period, cur)
	c = book.company
	cats = {}
	c.ledger.each { |e|
	  d = Date.parse(e.date)
	  next unless period.in_range(d)
	  cid = e.category
	  cid = 'Misc' if e.category.nil? || 0 == e.category.size
	  cat = cats[cid]
	  if cat.nil?
	    cat = Cat.new(book, cid)
	    cats[cid] = cat
	  end
	  cat.add(e, book, cur)
	}
	c.accounts.each { |a|
	  next unless Model::Account::FX_LOSS == a.kind
	  cat = cats[a.name]
	  if cat.nil?
	    cat = Cat.new(book, a.name)
	    cats[a.name] = cat
	  end
	  a.transactions.each { |tx|
	    d = Date.parse(tx.date)
	    next unless period.in_range(d)
	    cat.add_tx(tx.amount, a.currency, a.amount_in_currency(book, tx.amount, cur, tx.date))
	  }
	}
	cats
      end

    end
  end
end
