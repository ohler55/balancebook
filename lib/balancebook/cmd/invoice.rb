# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Invoice < Cmd

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

    end
  end
end
