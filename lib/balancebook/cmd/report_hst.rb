# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'balancebook/cmd/report_base'

module BalanceBook
  module Cmd

    class ReportHST < ReportBase

      attr_accessor :who
      attr_accessor :amount
      attr_accessor :tax
      attr_accessor :before
      attr_accessor :_income
      attr_accessor :_expense
      attr_accessor :_due
      attr_accessor :_paid

      def initialize(book=nil, e=nil)
	unless e.nil?
	  @date = e.date
	  @who = e.who
	  @amount = e.amount_in_currency(book, 'CAD')
	  @tax = e.tax('HST')
	  @before = @amount - @tax
	end
      end

      def due
	return @_due unless @_due.nil?
	return @tax if !@tax.nil? && 0.0 < @tax
	nil
      end

      def paid
	return @_paid unless @_paid.nil?
	return -@tax if !@tax.nil? && @tax < 0.0
	nil
      end

      def income
	return @_income unless @_income.nil?
	return @before if !@before.nil? && 0.0 < @before
	nil
      end

      def expense
	return @_expense unless @_expense.nil?
	return -@before if !@before.nil? && @before < 0.0
	nil
      end

      def self.name
	'hst'
      end

      def self.description
	'Summary of HST for a period.'
      end

      def self.help_cmds
	[
	  Help.new('hst', nil, 'HST paid and owed', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'reverse' => 'Reverse the order of the entries',
		     'cra' => 'Include CRA payments and refunds',
		   }),
	]
      end

      def self.report(book, args, hargs)
	period = extract_period(book, hargs)
	tsv = hargs.has_key?(:tsv)
	csv = hargs.has_key?(:csv)
	rev = hargs.has_key?(:reverse)
	with_cra = hargs.has_key?(:cra)

	table = Table.new("HST Report from #{period.first} to #{period.last}", [
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -1, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Income', 10, :income, '%.2f'),
			  Col.new('Expense', 10, :expense, '%.2f'),
			  Col.new("Tax Due", 10, :due, '%.2f'),
			  Col.new("Tax Paid", 10, :paid, '%.2f'),
			  ])
	total = 0.0
	income = 0.0
	expense = 0.0
	due = 0.0
	paid = 0.0
	book.company.ledger.each { |e|
	  d = Date.parse(e.date)
	  next unless period.in_range(d)
	  if e.category == 'HST' && with_cra
	    row = new(book, e)
	    row.tax = e.amount
	    table.add_row(row)
	    total += row.tax
	    if row.amount < 0.0
	      paid -= row.amount
	    else
	      due -= row.amount
	    end
	    next
	  end
	  next unless 0.0 != e.tax('HST')
	  next if e.category == 'Invoice Payment'
	  row = new(book, e)
	  table.add_row(row)
	  total += row.tax
	  if row.tax < 0.0
	    paid -= row.tax
	    expense += row.expense
	  else
	    due += row.tax
	    income += row.income
	  end
	}
	book.company.invoices.each { |inv|
	  d = inv.submit_date
	  next unless period.in_range(d)
	  next unless 0.0 != inv.tax('HST')
	  row = new
	  row.date = d.to_s
	  row.who = inv.id
	  row.amount = inv.amount
	  row.tax = inv.tax('HST')
	  row.before = row.amount - row.tax
	  table.add_row(row)
	  total += row.tax
	  if row.tax < 0.0
	    paid += row.tax
	  else
	    due += row.tax
	  end
	  income += row.income unless row.income.nil?
	}
	table.rows.sort_by! { |row| row.date }
	table.rows.reverse! if rev
	table.add_row(new)

	sub = new
	sub.who = 'Sub Totals'
	sub._income = income
	sub._expense = expense
	sub._due = due
	sub._paid = paid
	table.add_row(sub)

	# Add balance line
	table.add_row(new)
	sum = new
	sum.who = 'Total'
	sum.tax = total
	table.add_row(sum)
	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display
	end
      end

    end
  end
end
