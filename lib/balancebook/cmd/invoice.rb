# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Invoice
      extend Base

      def self.show(book, args={})
	puts "*** TBD show invoice"
      end

      def self.list(book, args={})
	first, last = extract_date_range(book, args)
	paid = args[:paid]
	paid = paid.downcase == "true" unless paid.nil?
	cust = args[:cust] || args[:customer]

	puts "\nInvoices"  if $verbose
	puts "ID            To              Amount  Submitted   Paid On"
	book.company.invoices.each { |inv|
	  date = Date.parse(inv.submitted)
	  next if date < first || last < date
	  unless paid.nil?
	    ip = inv.paid
	    next if paid && ip.nil?
	    next if !paid && !ip.nil?
	  end
	  next if !cust.nil? && cust != inv.to

	  puts "%-10s  %-10s  %10.2f  %-10s  %-10s" % [inv.id, inv.to, inv.amount, inv.submitted, inv.paid]
	}
	puts
      end

      def self.create(book, args)
	puts "\nEnter information for a new Invoice"
	model = Model::Invoice.new
	model.id = args[:id] || read_str('ID')
	model.submitted = args[:submitted] || read_date('Submitted')
	model.to = args[:to] || read_str('To')
	model.amount = args[:amount] || read_amount('Amount')
	model.amount= model.amount.to_f
	tax = args[:tax] || read_str('Tax')
	if 0 < tax.size
	  ta = make_taxes(book, tax, model.amount)
	  puts taxes.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	  model.taxes = ta
	end
	model.validate(book)
	model
      end

      def self.make_taxes(book, tax_input, amount)
	ids = tax_input.split(',').map { |id| id.strip }

	return nil if 0 == ids[0].size
	taxes = []
	ids.each { |id|
	  tax = book.company.find_tax(id)
	  raise StandardError.new("Could not find #{id} tax.") if tax.nil?

	  # TBD broken for multiple taxes
	  ta = Model::TaxAmount.new(id, (amount * tax.percent / (tax.percent + 100.0) * 100.0).to_i / 100.0)
	  taxes << ta
	}
	taxes
      end

    end
  end
end
