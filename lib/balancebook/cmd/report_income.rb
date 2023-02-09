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

	def initialize(id)
	  @id = id
	  @amount = 0.0
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

	def add(e)
	  c = @curs[e.currency]
	  if c.nil?
	    c = Cur.new(e.currency)
	    @curs[c.id] = c
	  end
	  c.amount += e.amount
	end

	def add_tx(amount, tx_cur)
	  c = @curs[tx_cur]
	  if c.nil?
	    c = Cur.new(tx_cur)
	    @curs[c.id] = c
	  end
	  c.amount += amount
	end

	def empty?
	  @curs.each_value { |c|
	    return false if 0.0 != c.amount.round(2)
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
		     'accrual' => 'Use Accrual account method',
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
	accrual = hargs.has_key?(:accrual)
	cur = book.fx.base
	if hargs.has_key?(:currency)
	  cur = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	end
	parens = hargs.has_key?(:parens)
	money_fmt = parens ? :money : '%.2f'
	money_size = parens ? 11 : 10
	method = accrual ? 'Accrual' : 'Cash'
	table = Table.new("#{c.name} #{method} Income Statement from #{period.first} to #{period.last} in #{cur}", [
			    Col.new('', -1, :label, nil),
			    Col.new('', money_size, :plus, money_fmt),
			    Col.new('', money_size, :base_plus, money_fmt),
			    Col.new('', money_size, :neg, money_fmt),
			    Col.new('', money_size, :base_neg, money_fmt),
			  ])

	cats = by_cat(book, period, cur)
	if accrual
	  report_accrual(book, c, period, cur, cats, table)
	else
	  report_cash(book, c, period, cur, cats, table)
	end

	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display(false)
	end
      end

      def self.report_accrual(book, c, period, cur, cats, table)
	table.add_row(nil)
	revenue = add_accrual_revenue(table, cats, book, period, cur)
	table.add_row(nil)
	expenses = add_accrual_expenses(table, cats, book, period, cur)
	table.add_row(nil)

	row = GenRow.new
	row.label = 'Net Income'
	row.base_neg = revenue - expenses
	row.ansi = BOLD
	table.add_row(row)
      end

      def self.report_cash(book, c, period, cur, cats, table)
	table.add_row(nil)
	revenue = add_revenue(table, cats, book, period, cur)
	table.add_row(nil)
	expenses = add_expenses(table, cats, book, period, cur)
	table.add_row(nil)

	row = GenRow.new
	row.label = 'Net Income'
	row.base_neg = revenue - expenses
	row.ansi = BOLD
	table.add_row(row)
      end

      def self.add_revenue(table, cats, book, period, cur)
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	row = GenRow.new
	row.label = 'Revenue'
	row.base_plus = cur
	row.base_neg = cur
	row.ansi = BOLD + UNDERLINE
	table.add_row(row)

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
	      cur_rate = book.fx.find_rate(c.id, period.last)
	      row.base_neg = (c.amount * base_rate / cur_rate).round(2)
	      table.add_row(row)
	      total += row.base_neg
	    }
	  else
	    c = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{c.id})"
	    row.neg = c.amount
	    cur_rate = book.fx.find_rate(c.id, period.last)
	    row.base_neg = (c.amount * base_rate / cur_rate).round(2)
	    table.add_row(row)
	    total += row.base_neg
	  end
	}
	table.add_row(nil)
	row = GenRow.new
	row.label = '  Revenue Total'
	row.base_neg = total
	row.ansi = BOLD
	table.add_row(row)

	total
      end

      def self.add_expenses(table, cats, book, period, cur)
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	row = GenRow.new
	row.label = 'Expenses'
	row.base_plus = cur
	row.base_neg = cur
	row.ansi = BOLD + UNDERLINE
	table.add_row(row)

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
	      cur_rate = book.fx.find_rate(c.id, period.last)
	      row.base_plus = (-c.amount * base_rate / cur_rate).round(2)
	      table.add_row(row)
	      total += row.base_plus
	    }
	  else
	    c = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{c.id})"
	    row.plus = -c.amount
	    cur_rate = book.fx.find_rate(c.id, period.last)
	    row.base_plus = (-c.amount * base_rate / cur_rate).round(2)
	    table.add_row(row)
	    total += row.base_plus
	  end
	}
	table.add_row(nil)
	row = GenRow.new
	row.label = '  Cash Total'
	row.base_plus = total
	row.ansi = BOLD
	table.add_row(row)

	total
      end

      def self.by_cat(book, period, cur)
	c = book.company
	cats = {}
	sum = 0.0
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
	  cat.add(e)
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
	    cat.add_tx(tx.amount, a.currency)
	    #cat.add_tx(tx.amount, a.currency, a.amount_in_currency(book, tx.amount, cur, tx.date))
	  }
	}
	cats
      end

      def self.add_accrual_revenue(table, cats, book, period, cur)
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	row = GenRow.new
	row.label = 'Revenue'
	row.base_plus = cur
	row.base_neg = cur
	row.ansi = BOLD + UNDERLINE
	table.add_row(row)

	total = 0.0
	cats.keys.sort.each { |k|
	  cat = cats[k]
	  next unless false == cat.expense
	  next if cat.empty?
	  next if cat.id == 'T2 Withholding' # pre-2020
	  next if cat.id == 'Invoice Payment'

	  if 1 < cat.curs.size
	    row = GenRow.new
	    row.label = "  #{cat.id}"
	    table.add_row(row)

	    cat.curs.each { |_,c|
	      row = GenRow.new
	      row.label = "    #{c.id}"
	      row.neg = c.amount
	      cur_rate = book.fx.find_rate(c.id, period.last)
	      row.base_neg = (c.amount * base_rate / cur_rate).round(2)
	      table.add_row(row)
	      total += row.base_neg
	    }
	  else
	    cv = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{cv.id})"
	    row.neg = cv.amount
	    cur_rate = book.fx.find_rate(cv.id, period.last)
	    row.base_neg = (cv.amount * base_rate / cur_rate).round(2)
	    table.add_row(row)
	    total += row.base_neg
	  end
	}
	curs = []
	c.invoices.each { |inv|
	  d = Date.parse(inv.submitted)
	  next unless period.in_range(d)
	  next if curs.include?(inv.currency)
	  curs << inv.currency
	}
	inv_total = 0.0
	if 1 <= curs.size
	    row = GenRow.new
	    row.label = '  Invoice'
	    table.add_row(row)
	    curs.each { |cr|
	      cur_total = 0.0
	      base_total = 0.0
	      c.invoices.each { |inv|
		d = Date.parse(inv.submitted)
		next unless period.in_range(d)
		next unless inv.currency == cr
		cur_total += inv.amount
		base_total += inv.amount_in_currency(cur)
                # to exclude withheld...
		#cur_total += inv.income
		#cur_rate = book.fx.find_rate(cr, period.last)
		#income = (inv.income * base_rate / cur_rate).round(2)
		#base_total += income
	      }
	      row = GenRow.new
	      row.label = "    #{cr}"
	      row.neg = cur_total
	      row.base_neg = base_total
	      table.add_row(row)
	      inv_total += row.base_neg
	  }
	else
	  cur_total = 0.0
	  base_total = 0.0
	  c.invoices.each { |inv|
	    d = Date.parse(inv.submitted)
	    next unless period.in_range(d)
	    cur_total += inv.amount
	    base_total += inv.amount_in_currency(cur)
            # to exclude withheld...
	    #cur_total += inv.income
	    #cur_rate = book.fx.find_rate(inv.currency, period.last)
	    #income = (inv.income * base_rate / cur_rate).round(2)
	    #base_total += income
	  }
	  row = GenRow.new
	  row.label = "  Invoices (#{curs[0]})"
	  row.neg = cur_total
	  row.base_neg = base_total
	  table.add_row(row)
	  inv_total += row.base_neg
	end
	total += inv_total

	table.add_row(nil)
	row = GenRow.new
	row.label = '  Revenue Total'
	row.base_neg = total
	row.ansi = BOLD
	table.add_row(row)

	total
      end

      def self.add_accrual_expenses(table, cats, book, period, cur)
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	row = GenRow.new
	row.label = 'Expenses'
	row.base_plus = cur
	row.base_neg = cur
	row.ansi = BOLD + UNDERLINE
	table.add_row(row)

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
	      cur_rate = book.fx.find_rate(c.id, period.last)
	      row.base_plus = (-c.amount * base_rate / cur_rate).round(2)
	      table.add_row(row)
	      total += row.base_plus
	    }
	  else
	    c = cat.curs.values[0]
	    row = GenRow.new
	    row.label = "  #{cat.id} (#{c.id})"
	    row.plus = -c.amount
	    cur_rate = book.fx.find_rate(c.id, period.last)
	    row.base_plus = (-c.amount * base_rate / cur_rate).round(2)
	    table.add_row(row)
	    total += row.base_plus
	  end
	}
	total += add_payable_row(table, book, period, cur, true)

	table.add_row(nil)
	row = GenRow.new
	row.label = '  Expense Total'
	row.base_plus = total
	row.ansi = BOLD
	table.add_row(row)

	total
      end

    end
  end
end
