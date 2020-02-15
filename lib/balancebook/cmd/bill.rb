# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Bill
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a bill', {'id' => 'ID of the bill to delete.'}),
	  Help.new('list', nil, 'List all bills.', {
		     'paid' => 'Only display paid if true, only unpaid if false',
		     'from' => 'Only show bills for specified corporation',
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		   }),
	  Help.new('new', ['create'], 'Create a new bill.', {
		     'from' => 'Corporation the bill was received from',
		     'id' => 'ID of the bill',
		     'received' => 'Date the bill was received',
		     'amount' => 'Total amount of the bill',
		     'currency' => 'Currency the bill amount is in',
		     'tax' => 'Tax that was applied, e.g, HST',
		   }),
	  Help.new('pay', nil, 'Pay an bill.', {
		     'from' => 'Corporation the bill was received from',
		     'id' => 'ID of the bill',
		     'lid' => 'Ledger Entry ID of payment',
		   }),
	  Help.new('show', ['details'], 'Show bill details.', {
		     'from' => 'Corporation the bill was received from',
		     'id' => 'ID of the bill to display',
		   }),
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
	  raise StandardError.new("Bill can not #{verb}.")
	end
      end

      def self.delete(book, args, hargs)
	# TBD
	puts "Not implemented yet"
      end

      def self.show(book, args, hargs)
	c = book.company
	from = extract_arg(:from, "From", args, hargs, c.bills.map { |bill| bill.from })

	id = extract_arg(:id, "ID", args, hargs, c.bills.select { |bill| bill.from == from }.map { |bill| bill.id })
	bill = c.find_bill(from, id)
	raise StandardError.new("Failed to find bill #{id}.") if bill.nil?
	cur = book.fx.find_currency(bill.currency)

	puts "\nFrom: #{bill.from}"
	puts "ID: #{bill.id}"
	puts "File: #{bill.file}"
	puts "Received: #{bill.received}"
	puts "Amount: #{cur.symbol}#{bill.amount}"
	puts "Currency: #{bill.currency}"
	unless bill.taxes.nil?
	  puts "Taxes:"
	  bill.taxes.each { |ta|
	    puts "  #{ta.tax}: #{cur.symbol}#{ta.amount}"
	  }
	end
	unless bill.payments.nil?
	  puts "Payments:"
	  bill.payments.each { |lid|
	    lx = book.company.find_entry(lid)
	    puts "  #{cur.symbol}#{-lx.amount} on #{lx.date}"
	  }
	end
	puts
      end

      def self.list(book, args, hargs)
	table = Table.new('Bills', [
			  Col.new('From', -16, :from, nil),
			  Col.new('ID', -20, :id, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Cur', 3, :currency, nil),
			  Col.new('Received', -10, :received, nil),
			  Col.new('Paid On', -10, :paid, nil),
			  ])

	period = extract_period(book, hargs)

	paid = hargs[:paid]
	paid = paid.downcase == "true" unless paid.nil?
	from = hargs[:from] || hargs[:corporation]

	unless book.company.bills.nil?
	  book.company.bills.each { |bill|
	    date = Date.parse(bill.received)
	    next unless period.in_range(date)
	    unless paid.nil?
	      ip = bill.paid
	      next if paid && ip.nil?
	      next if !paid && !ip.nil?
	    end
	    next if !from.nil? && from != bill.from
	    table.add_row(bill)
	  }
	end
	table.display
      end

      def self.create(book, args, hargs)
	c = book.company
	puts "\nEnter information for a new Bill"
	model = Model::Bill.new
	model.from = extract_arg(:from, 'From', args, hargs, c.corporations.map { |c| c.id })
	model.id = extract_arg(:id, 'ID', args, hargs)
	model.received = extract_date(:recevied, 'Received', args, hargs)
	model.amount = extract_amount(:amount, 'Amount', args, hargs)
	model.currency = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	tax = extract_arg(:tax, 'Tax', args, hargs, c.taxes.map { |t| t.id })
	if 0 < tax.size
	  ta = make_taxes(book, tax, model.amount)
	  puts ta.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	  model.taxes = ta
	end
	model.validate(book)
	book.company.add_bill(book, model)
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
	partial = hargs[:partial]
	partial = partial.downcase == "true" unless partial.nil?

	c = book.company
	puts "\nEnter Bill payment information"
	from = extract_arg(:from, "From", args, hargs, c.bills.select { |bill| !bill.paid_in_full }.map { |bill| bill.from })
	id = extract_arg(:id, "ID", args, hargs,
			 c.bills.select { |bill| bill.from == from && !bill.paid_in_full }.map { |bill| bill.id })
	bill = c.find_bill(from, id)
	raise StandardError.new("Failed to find bill #{from} - #{id}.") if bill.nil?

	if partial
	  candidates = c.ledger.select { |lx|
	    -lx.amount <= bill.amount && bill.received <= lx.date && lx.category == 'Bill Payment' && !a_payment?(c, lx)
	  }.map { |lx| lx.id.to_s }
	else
	  candidates = c.ledger.select { |lx| -lx.amount == bill.amount && bill.received <= lx.date}.map { |lx| lx.id.to_s }
	end
	lid = extract_arg(:lid, "Ledger Entry ID", args, hargs, candidates).to_i
	lx = c.find_entry(lid)
	raise StandardError.new("Failed to find ledger entry #{lid}.") unless candidates.include?(lid.to_s)
	raise StandardError.new("Bill payments already includes ledger entry #{lid}.") if !bill.payments.nil? && bill.payments.include?(lid)
	bill.pay(lid)

	puts "\nPayment of #{bill.amount} on #{id} from #{bill.from}.\n\n"
	book.company.dirty
      end

      def self.a_payment?(c, lx)
	c.bills.each { |bill| return true if !bill.payments.nil? &&bill.payments.include?(lx.id) }
	false
      end

    end
  end
end
