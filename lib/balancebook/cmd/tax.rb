# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Tax
      extend Base

      def self.list(book, args={})
	table = Table.new('Taxes', [
			  Col.new('ID', -10, :id, nil),
			  Col.new('Percent', 10, :percent, '%.2f%%')])
	table.rows = book.company.taxes
	table.display
      end

      def self.create(book, args={})
	puts "\nCreate Tax"
	id = args[:id] || read_str('id')
	percent = args[:percent] || read_float('Percent')
	tax = nil
	if book.company.find_tax(id).nil?
	  tax = Model::Tax.new(id, percent)
	  puts "#{id} created"
	else
	  puts "#{id} already exists"
	end
	tax
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
