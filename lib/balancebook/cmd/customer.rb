# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Customer
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a customer', {'name' => 'Name of customer to delete.'}),
	  Help.new('list', nil, 'List all customers.', nil),
	  Help.new('new', ['create'], 'Create a new customer.', {
		     'name' => 'Name of the customer',
		     'addr' => 'Address of bank',
		     'currency' => 'Currency of the account',
		     'note' => 'Any additional information about the customer',
		   }),
	  Help.new('show', ['details'], 'Show customer details.', {'id' => 'Name of customer to display.'}),
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
	puts "\nEnter information for a new Customer"
	model = Model::Customer.new
	model.id = extract_arg(:name, "Name", args, hargs)
	model.currency = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	raise StandardError.new("Currency #{model.currency} not found.") if book.fx.find_currency(model.currency).nil?
	model.address = extract_arg(:addr, "Address", args, hargs)
	model.notes = extract_arg(:note, "Note", args, hargs)
	book.company.add_customer(model)
	puts "\n#{model.class.to_s.split('::')[-1]} #{model.id} added.\n\n"
	book.company.dirty
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
