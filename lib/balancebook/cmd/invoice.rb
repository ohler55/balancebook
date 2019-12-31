# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Invoice
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a invoice', {'id' => 'ID of the invoice to delete.'}),
	  Help.new('list', nil, 'List all invoices.', {
		     'paid' => 'Only display paid if true, only unpaid if false',
		     'cust' => 'Only show invoices for specified customer',
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		   }),
	  Help.new('new', ['create'], 'Create a new invoice.', {
		     'id' => 'ID of the invoice',
		     'submitted' => 'Date the invoice was submitted',
		     'to' => 'Customer the invoice was submitted to',
		     'amount' => 'Total amount of the invoice',
		     'currency' => 'Currency the invoice amount is in',
		     'tax' => 'Tax that was applied, e.g, HST',
		   }),
	  Help.new('pay', nil, 'Pay an invoice.', nil),
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
	# TBD
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
	puts "PO: #{inv.po}"
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
	  inv.payments.each { |p|
	    puts "  #{cur.symbol}#{p.amount} on #{p.date}"
	  }
	end
	puts
      end

      def self.list(book, args, hargs)
	table = Table.new('Invoices', [
			  Col.new('ID', -16, :id, nil),
			  Col.new('To', -16, :to, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Cur', 3, :currency, nil),
			  Col.new('Submitted', -10, :submitted, nil),
			  Col.new('Paid On', -10, :paid, nil),
			  ])

	period = extract_period(book, hargs)

	paid = hargs[:paid]
	paid = paid.downcase == "true" unless paid.nil?
	cust = hargs[:cust] || hargs[:customer]

	book.company.invoices.each { |inv|
	  date = Date.parse(inv.submitted)
	  next unless period.in_range(date)
	  unless paid.nil?
	    ip = inv.paid
	    next if paid && ip.nil?
	    next if !paid && !ip.nil?
	  end
	  next if !cust.nil? && cust != inv.to
	  table.add_row(inv)
	}
	table.display
      end

      def self.create(book, args, hargs)
	c = book.company
	puts "\nEnter information for a new Invoice"
	model = Model::Invoice.new
	model.id = extract_arg(:id, 'ID', args, hargs)
	model.submitted = extract_date(:submitted, 'Submitted', args, hargs)
	model.to = extract_arg(:to, 'To', args, hargs, c.customers.map { |c| c.id })
	model.amount = extract_amount(:amount, 'Amount', args, hargs)
	model.currency = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	tax = extract_arg(:tax, 'Tax', args, hargs, c.taxes.map { |t| t.id })
	if 0 < tax.size
	  ta = make_taxes(book, tax, model.amount)
	  puts ta.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	  model.taxes = ta
	end
	model.validate(book)
	book.company.add_invoice(book, model)
	puts "\n#{model.class.to_s.split('::')[-1]} #{model.id} added.\n\n"
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
	c = book.company
	puts "\nEnter Invoice payment information"
	id = extract_arg(:id, "ID", args, hargs, c.invoices.select { |inv| !inv.paid_in_full }.map { |inv| inv.id })
	inv = c.find_invoice(id)
	raise StandardError.new("Failed to find invoice #{id}.") if inv.nil?
	model = Model::Payment.new
	model.account = extract_arg(:account, 'Account', args, hargs, c.accounts.map { |a| a.id } + c.accounts.map { |a| a.name })
	model.date = extract_amount(:date, 'Date', args, hargs)
	model.amount = extract_amount(:amount, 'Amount', args, hargs)
	model.note = extract_arg(:note, 'Note', args, hargs)
	inv.pay(model)
	puts "\nPayment of #{model.amount} to #{id} made.\n\n"
	book.company.dirty
      end

    end
  end
end
