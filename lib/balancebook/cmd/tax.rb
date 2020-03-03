# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Tax
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a tax', {'id' => 'ID of tax to delete.'}),
	  Help.new('list', nil, 'List all taxes.', nil),
	  Help.new('new', ['create'], 'Create a new tax.', {
		     'id' => 'ID of the tax',
		     'pecent' => 'Tax percent',
		   }),
	  Help.new('show', ['details'], 'Show tax details.', {'id' => 'ID of tax to display.'}),
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
	  raise StandardError.new("Tax can not #{verb}.")
	end
      end

      def self.list(book, args, hargs)
	table = Table.new('Taxes', [
			  Col.new('ID', -10, :id, nil),
			  Col.new('Percent', 10, :percent, '%.2f%%')])
	table.rows = book.company.taxes
	table.display
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.taxes.map { |t| t.id })

	tax = c.find_tax(id)
	raise StandardError.new("Failed to find tax #{id}.") if tax.nil?
	puts "\n#{UNDERLINE}#{tax.id}#{' '*(80 - tax.id.size)}#{NORMAL}"
	puts "ID:                #{tax.id}"
	puts "Percent:           #{tax.percent.round(2)}%"
	puts
      end

      def self.create(book, args={})
	puts "\nCreate Tax"
	id = args[:id] || read_str('id')
	percent = args[:percent] || read_float('Percent')
	tax = nil
	if book.company.find_tax(id).nil?
	  tax = Model::Tax.new(id, percent)
	  @company.add_tax(self, tax)
	  puts "#{id} created"
	  book.company.dirty
	else
	  puts "#{id} already exists"
	end
      end

      def self.delete(book, args={})
	puts "\nDelete Tax"
	deleted = false
	id = args[:id] || read_str('id')
	tax = book.company.find_tax(id)
	if tax.nil?
	  puts "'#{id}' does not exist"
	elsif book.company.tax_used?(id)
	  puts "'#{id}' still in use"
	else
	  book.company.tax_del(tax.id)
	  deleted = true
	  puts "'#{id}' deleted"
	end
	deleted
      end


    end
  end
end
