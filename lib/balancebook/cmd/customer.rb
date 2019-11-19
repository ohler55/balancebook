# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Customer
      extend Base

      def self.list(book, args={})
	table = Table.new('Customers', [
			  Col.new('Name', -20, :id, nil),
			  Col.new('Address', -60, :address, nil),
			  ])

	table.rows = book.company.customers
	table.display
      end

      def self.show(book, args={})
	id = args[:id]
	cust = book.company.find_customer(id)
	raise StandardError.new("Failed to find customer #{id}.") if cust.nil?
	puts "\nCustomer #{cust.id}"
	puts "Currency: #{cust.currency}"
	puts "Address: #{cust.address}"
	unless cust.contacts.nil?
	  puts 'Contacts:'
	  cust.contacts.each { |c|
	    puts "  #{c.id}"
	    puts "    Name: #{c.name}"
	    puts "    Role: #{c.role}"
	    puts "    Email: #{c.email}"
	    puts "    Phone: #{c.phone}"
	  }
	end
	unless cust.notes.nil?
	  puts 'Notes:'
	  cust.notes.each { |n| puts "  - #{n}" }
	end
	puts
      end

    end
  end
end
