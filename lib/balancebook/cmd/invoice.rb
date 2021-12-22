# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Invoice
      extend Base

      attr_accessor :id
      attr_accessor :to
      attr_accessor :po
      attr_accessor :amount
      attr_accessor :base_amount
      attr_accessor :off_amount
      attr_accessor :currency
      attr_accessor :submitted
      attr_accessor :paid_on
      attr_accessor :income
      attr_accessor :withheld
      attr_accessor :paid
      attr_accessor :t2
      attr_accessor :penalty
      attr_accessor :late
      attr_accessor :is_penalty
      attr_accessor :ansi

      def initialize(inv, as_of, off=0)
	unless inv.nil?
	  @id = inv.id
	  @to = inv.to
	  @po = inv.po
	  @amount = inv.amount
	  @withheld = inv.withheld.to_f
	  @base_amount = inv.amount - inv.tax
	  @off_amount = inv.amount - (inv.tax * off.to_f / 100.0)
	  @currency = inv.currency
	  @submitted = inv.submitted
	  @paid_on = inv.paid(false) # first payment is enough
	  @paid = inv.paid_amount
	  #@t2 = @amount - @paid
	  @t2 = @withheld
	  # TBD consider if t2 has been paid back
	  if inv.refunds.is_a?(Array)
	    inv.refunds.each { |lid|
	      # TBD put in model invoice
	      lx = inv._company.find_entry(lid)
	      @t2 -= lx.amount
	    }
	  end
	  @t2 = nil if 0.0 == @t2
	  @penalty = inv.penalty(as_of)
	  @late = inv.days_late(as_of)
	  @is_penalty = inv.is_penalty ? '*' : ' '
	  @income = @amount - @withheld

=begin
	  unless inv.payments.nil?
	    if 1 < inv.payments.size
	      most = 0.0
	      inv.payments.each { |lid|
		lx = inv._company.find_entry(lid)
		most = lx.amount unless lx.nil? || most < lx.amount
	      }
	      @income = most
	      @withheld = @amount - @income
	    elsif inv.paid_in_full
	      @income = @amount
	    else
	      @income = inv.paid_amount
	      @withheld = @amount - @income
	    end
	  end
=end
	end
	@ansi = nil
      end

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a invoice', {'id' => 'ID of the invoice to delete.'}),
	  Help.new('list', nil, 'List all invoices.', {
		     'paid' => 'Only display paid if true, only unpaid if false',
		     'cust' => 'Only show invoices for specified corporation',
		     'po' => 'Only show invoices for specified PO, * indicates all',
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'reverse' => 'Reverse the order of the entries',
		     'as_of' => 'Date to calculate penalties from. - and today are valid.',
		     'off' => 'Percent off of taxes for customer, e.g., 83%',
		   }),
	  Help.new('new', ['create'], 'Create a new invoice.', {
		     'id' => 'ID of the invoice',
		     'submitted' => 'Date the invoice was submitted',
		     'to' => 'Corporation the invoice was submitted to',
		     'amount' => 'Total amount of the invoice',
		     'currency' => 'Currency the invoice amount is in',
		     'tax' => 'Tax that was applied, e.g, HST',
		   }),
	  Help.new('pay', nil, 'Pay an invoice.', {
		     'id' => 'ID of the invoice',
		     'lid' => 'Ledger Entry ID of the payment',
		     'partial' => 'True for partial payments',
		   }),
	  Help.new('show', ['details'], 'Show invoice details.', {'id' => 'ID of the invoice to display'}),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'delete', 'del', 'rm'
	  delete(book, args[1..-1], hargs)
	when 'list'
	  list(book, args[1..-1], hargs)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	when 'pay', 'payment'
	  pay(book, args[1..-1], hargs)
	when 'show'
	  show(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Invoice can not #{verb}.")
	end
      end

      def self.delete(book, args, hargs)
	# TBD delete not implemented yet
	puts "Not implemented yet"
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.invoices.map { |inv| inv.id })
	inv = c.find_invoice(id)
	raise StandardError.new("Failed to find invoice #{id}.") if inv.nil?
	cur = book.fx.find_currency(inv.currency)

	puts "\nID: #{inv.id}"
	puts "To: #{inv.to}"
	puts "Submitted: #{inv.submitted}"
	puts "Amount: #{cur.symbol}#{inv.amount}"
	puts "Currency: #{inv.currency}"
	unless inv.taxes.nil?
	  puts "Taxes:"
	  inv.taxes.each { |ta|
	    puts "  #{ta.tax}: #{cur.symbol}#{ta.amount}"
	  }
	end
	unless inv.payments.nil?
	  puts "Payments:"
	  inv.payments.each { |lid|
	    lx = book.company.find_entry(lid)
	    puts "  #{cur.symbol}#{lx.amount} on #{lx.date}"
	  }
	end
	puts
      end

      def self.header(table, to, cur)
	row = new(nil, nil)
	row.id = "#{to} #{cur}"
	row.is_penalty = 'P'
	row.amount = 'Gross'
	row.base_amount = 'Pre Tax'
	row.income = 'Income'
	row.withheld = 'Withheld'
	row.submitted = 'Submitted'
	row.paid_on = 'Paid On'
	row.paid = 'Paid'
	row.t2 = 'Pending T2'
	row.ansi = BOLD + UNDERLINE
	table.add_row(row)
      end

      def self.list(book, args, hargs)
	as_of = nil
	if hargs.has_key?(:as_of)
	  as_of = extract_date(:as_of, 'As Of', args, hargs)
	  as_of = Date.parse(as_of) unless as_of.nil?
	end
	period = extract_period(book, hargs)
	show_period = hargs.has_key?(:period) || hargs.has_key?(:first) || hargs.has_key?(:last)
	paid = hargs[:paid]
	paid = paid.downcase == "true" unless paid.nil?
	cust = hargs[:cust] || hargs[:corporation]
	po = hargs[:po]
	off = hargs[:off]
	off = off.to_i unless off.nil?
	tsv = hargs.has_key?(:tsv)
	csv = hargs.has_key?(:csv)
	rev = hargs.has_key?(:reverse)

	cols = [
	  Col.new('ID', -16, :id, nil),
	  Col.new('P', 1, :is_penalty, nil),
	  Col.new('Amount', 10, :amount, '%.2f'),
	  Col.new('Pre Tax', 10, :base_amount, '%.2f'),
	  Col.new('Income', 10, :income, '%.2f'),
	  Col.new('Withheld', 10, :withheld, '%.2f'),
	  Col.new('Submitted', -10, :submitted, nil),
	  Col.new('Paid On', -10, :paid_on, nil),
	  Col.new('Paid', 10, :paid, '%.2f'),
	  Col.new('Pending T2', 10, :t2, '%.2f'),
	]
	unless off.nil?
	  cols.insert(5, Col.new('83% Off', 10, :off_amount, '%.2f'))
	end
	unless po.nil?
	  cols.insert(3, Col.new('PO', -1, :po, nil))
	end
	unless as_of.nil?
	  cols << Col.new('Penalty', -10, :penalty, '%.2f')
	  cols << Col.new('Late', -5, :late, '%d')
	end
	title = 'Invoices'
	title += " for #{cust}" unless cust.nil?
	title += " PO #{po}" unless po.nil?
	title += " between #{period.first} and #{period.last}" if show_period
	table = Table.new(title, cols)

	table.add_row(new(nil, nil))
	tos = {}
	book.company.invoices.each { |inv|
	  date = Date.parse(inv.submitted)
	  next unless period.in_range(date)
	  tos[inv.to] = inv.currency unless tos.include?(inv.to)
	}
	tos.keys.sort.each { |to|
	  row = new(nil, nil)
	  header(table, to, tos[to])

	  total = 0.0
	  tax = 0.0
	  penalty = 0.0
	  paid_total = 0.0
	  paid_penalty = 0.0
	  adj_total = 0.0
	  adj_penalty = 0.0
	  with_total = 0.0
	  t2_total = 0.0

	  book.company.invoices.reverse.each { |inv|
	    date = Date.parse(inv.submitted)
	    next unless period.in_range(date)
	    next unless inv.to == to
	    unless paid.nil?
	      ip = inv.paid
	      next if paid && ip.nil?
	      next if !paid && !ip.nil?
	    end
	    next if !cust.nil? && cust != inv.to
	    next if !po.nil? && '*' != po && po != inv.po
	    row = new(inv, as_of, off)
	    table.add_row(row)
	    total += inv.amount
	    tax += inv.tax
	    if inv.is_penalty
	      penalty += inv.amount
	      paid_penalty += inv.paid_amount
	      adj_penalty += inv.paid_amount
	    end
	    paid_total += inv.paid_amount
	    adj_total += row.income
	    with_total += row.withheld
	    t2_total += row.t2 unless row.t2.nil?
	  }
	  table.add_row(new(nil, nil))

	  row = new(nil, nil)
	  row.id = "#{to} Total"
	  row.amount = total
	  row.base_amount = total - tax
	  row.off_amount = total - (tax * 0.83)
	  row.paid = paid_total
	  row.income = adj_total
	  row.withheld = with_total
	  row.t2 = t2_total
	  table.add_row(row)

	  if 0.0 < paid_penalty
	    row = new(nil, nil)
	    row.id = 'Exclude Penalty'
	    row.amount = total - penalty
	    row.base_amount = total - tax - penalty
	    row.off_amount = total - (tax * 0.83) - penalty
	    row.paid = paid_total - paid_penalty
	    row.income = adj_total - adj_penalty
	    table.add_row(row)
	  end
	  table.add_row(new(nil, nil))
	}
	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display(false)
	end
      end

      def self.create(book, args, hargs)
	c = book.company
	puts "\nEnter information for a new Invoice"
	model = Model::Invoice.new
	model.id = extract_arg(:id, 'ID', args, hargs)
	model.submitted = extract_date(:submitted, 'Submitted', args, hargs)
	model.to = extract_arg(:to, 'To', args, hargs, c.corporations.map { |c| c.id })
	model.po = extract_arg(:po, 'PO', args, hargs)
	model.amount = extract_amount(:amount, 'Amount', args, hargs)
	model.currency = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	tax = extract_arg(:tax, 'Tax', args, hargs, c.taxes.map { |t| t.id })
	if 0 < tax.size
	  ta = make_taxes(book, tax, model.amount)
	  puts ta.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	  model.taxes = ta
	else
	  model.is_penalty = extract_boolean(:penalty, 'Penalty?', args, hargs)

	end
	model.validate(book)
	book.company.add_invoice(book, model)
	puts "\n#{model.class.to_s.split('::')[-1]} #{model.id} added.\n\n"
	puts "#{Oj.dump(model, indent: 2)}" if book.verbose
	book.company.dirty
      end

      def self.make_taxes(book, tax_input, amount)
	ids = tax_input.split(',').map { |id| id.strip }

	return nil if 0 == ids[0].size
	taxes = []
	ids.each { |id|
	  tax = book.company.find_tax(id)
	  raise StandardError.new("Could not find #{id} tax.") if tax.nil?

	  # TBD broken for multiple taxes
	  ta = Model::TaxAmount.new(tax.id, (amount * tax.percent / (tax.percent + 100.0) * 100.0).to_i / 100.0)
	  taxes << ta
	}
	taxes
      end

      def self.pay(book, args, hargs)
	partial = hargs[:partial]
	partial = partial.downcase == "true" unless partial.nil?

	c = book.company
	puts "\nEnter Invoice payment information"
	id = extract_arg(:id, "ID", args, hargs, c.invoices.select { |inv| !inv.paid_in_full }.map { |inv| inv.id })
	inv = c.find_invoice(id)
	raise StandardError.new("Failed to find invoice #{id}.") if inv.nil?

	if inv.paid_in_full
	  puts "\nInvoice #{inv.id} already paid in full.\n\n"
	  return
	end

	outstanding = inv.outstanding
	if partial
	  candidates = c.ledger.select { |lx|
	    lx.amount <= inv.amount && inv.submitted <= lx.date && lx.category == 'Invoice Payment' && !a_payment?(c, lx)
	  }.map { |lx| lx.id.to_s }
	else
	  candidates = c.ledger.select { |lx| lx.amount == outstanding && inv.submitted <= lx.date}.map { |lx| lx.id.to_s }
	end
	lid = extract_arg(:lid, "Ledger Entry ID", args, hargs, candidates).to_i
	lx = c.find_entry(lid)
	raise StandardError.new("Failed to find ledger entry #{lid}.") unless candidates.include?(lid.to_s)
	raise StandardError.new("Invoice payments already includes ledger entry #{lid}.") if inv.payments.include?(lid)
	if lx.category.downcase.include?('refund')
	  inv.refund(lid)
	else
	  inv.pay(lid)
	end
	puts "\nPayment of #{lx.amount} to #{id} made.\n\n"
	book.company.dirty
      end

      def self.a_payment?(c, lx)
	c.invoices.each { |inv| return true if !inv.payments.nil? &&inv.payments.include?(lx.id) }
	false
      end

    end
  end
end
