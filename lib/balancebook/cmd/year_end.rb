# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    module YearEnd

      def add_receivables_row(table, book, period, cur, left)
	c = book.company
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
	  row = GenRow.new
	  row.label = "  Accounts Receivable #{k}"
	  if left
	    row.plus = ar.amount
	    row.base_plus = ar.base_amount
	  else
	    row.neg = ar.amount
	    row.base_neg = ar.base_amount
	  end
	  table.add_row(row)
	  ar_total += ar.base_amount
	}
	ar_total
      end

      def add_previous_year_row(table, book, period, cur, left)
	sum = 0.0
	c = book.company
	base_rate = book.fx.find_rate(cur, period.last)
	arm = {}
	c.invoices.each { |inv|
	  d = Date.parse(inv.submitted)
	  next if period.first < d
	  out = inv.amount - inv.paid_amount_by(period.first)
	  next if out <= 0.0
	  next if out < 10000.0 # TBD cheat for T4 amounts. Need a better approach
	  ar = arm[inv.currency]
	  if ar.nil?
	    ar = CurAmount.new
	    arm[inv.currency] = ar
	  end
	  inv_rate = book.fx.find_rate(inv.currency, period.last)
	  ar.amount += out
	  ar.base_amount += (out * base_rate / inv_rate).round(2)
	  #puts "#{inv.id}  #{inv.submitted}  #{inv.submitted}  #{out} "
	  sum += out
	}
	ar_total = 0.0
	arm.each { |k,ar|
	  row = GenRow.new
	  row.label = "  Previous Year Income #{k}"
	  if left
	    row.plus = ar.amount
	    row.base_plus = ar.base_amount
	  else
	    row.neg = ar.amount
	    row.base_neg = ar.base_amount
	  end
	  table.add_row(row)
	  ar_total += ar.base_amount
	}
	ar_total
      end

      def add_payable_row(table, book, period, cur, left)
	c = book.company
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
	  row = GenRow.new
	  row.label = "  Accounts Payable #{k}"
	  if left
	    row.plus = ap.amount
	    row.base_plus = ap.base_amount
	  else
	    row.neg = ap.amount
	    row.base_neg = ap.base_amount
	  end
	  table.add_row(row)
	  ap_total += ap.base_amount
	}
	ap_total
      end

    end
  end
end
