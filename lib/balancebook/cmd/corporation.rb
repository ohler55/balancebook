# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Corporation
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a corporation', {'name' => 'Name of corporation to delete.'}),
	  Help.new('list', nil, 'List all corporations.', nil),
	  Help.new('new', ['create'], 'Create a new corporation.', {
		     'name' => 'Name of the corporation',
		     'addr' => 'Address of bank',
		     'currency' => 'Currency of the account',
		     'note' => 'Any additional information about the corporation',
		   }),
	  Help.new('show', ['details'], 'Show corporation details.', {'id' => 'Name of corporation to display.'}),
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
	  raise StandardError.new("Corporation can not #{verb}.")
	end
      end

      def self.list(book)
	table = Table.new('Corporations', [
			  Col.new('Name', -1, :id, nil),
			  Col.new('Address', -1, :address, nil),
			  ])
	table.rows = book.company.corporations
	table.display
      end

      def self.create(book, args, hargs)
	puts "\nEnter information for a new Corporation"
	model = Model::Corporation.new
	model.id = extract_arg(:name, "Name", args, hargs)
	model.currency = extract_arg(:currency, "Currency", args, hargs, book.fx.currencies.map { |c| c.id } + [book.fx.base])
	raise StandardError.new("Currency #{model.currency} not found.") if book.fx.find_currency(model.currency).nil?
	model.address = extract_arg(:addr, "Address", args, hargs)
	model.notes = extract_arg(:note, "Note", args, hargs)
	book.company.add_corporation(model)
	puts "\n#{model.class.to_s.split('::')[-1]} #{model.id} added.\n\n"
	book.company.dirty
      end

      def self.delete(book, args, hargs)
	# TBD
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, 'ID', args, hargs)
	corp = c.find_corporation(id)
	raise StandardError.new("Failed to find corporation #{id}.") if corp.nil?
	puts "\n#{UNDERLINE}#{corp.id}#{' ' * (80 - corp.id.size)}#{NORMAL}"
	puts "Currency:  #{corp.currency}"
	puts "Address:   #{corp.address}"
	unless corp.contacts.nil?
	  puts 'Contacts:'
	  corp.contacts.each { |c|
	    puts "  #{c.id}"
	    puts "    Name:  #{c.name}"
	    puts "    Role:  #{c.role}"
	    puts "    Email: #{c.email}"
	    puts "    Phone: #{c.phone}"
	  }
	end
	unless corp.notes.nil?
	  puts 'Notes:'
	  corp.notes.each { |n| puts "  - #{n}" }
	end
	puts
      end

    end
  end
end
