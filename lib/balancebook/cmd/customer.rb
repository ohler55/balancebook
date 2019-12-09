# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Customer
      extend Base

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'delete', 'del', 'rm'
	  delete(book, args[1..-1], hargs)
	when 'list'
	  list(book)
	when 'show'
	  show(book, args[1..-1], hargs)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Customer can not #{verb}.")
	end
      end

      def self.list(book)
	table = Table.new('Customers', [
			  Col.new('Name', -1, :id, nil),
			  Col.new('Address', -1, :address, nil),
			  ])
	table.rows = book.company.customers
	table.display
      end

      def self.create(book, args, hargs)
	# TBD
      end

      def self.delete(book, args, hargs)
	# TBD
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, 'ID', args, hargs)
	cust = c.find_customer(id)
	raise StandardError.new("Failed to find customer #{id}.") if cust.nil?
	puts "\n#{UNDERLINE}#{cust.id}#{' ' * (80 - cust.id.size)}#{NORMAL}"
	puts "Currency:  #{cust.currency}"
	puts "Address:   #{cust.address}"
	unless cust.contacts.nil?
	  puts 'Contacts:'
	  cust.contacts.each { |c|
	    puts "  #{c.id}"
	    puts "    Name:  #{c.name}"
	    puts "    Role:  #{c.role}"
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
