# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Category
      extend Base

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'delete', 'del', 'rm'
	  delete(book, args[1..-1], hargs)
	when 'list'
	  list(book)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Category can not #{verb}.")
	end
      end

      def self.list(book)
	table = Table.new('Categories', [
			  Col.new('Name', -1, :name, nil),
			  ])
	table.rows = book.company.categories
	table.display
      end

      def self.create(book, args, hargs)
	puts "\nCreate Category"
	c = book.company
	name = extract_arg(:name, 'Name', args, hargs)
	cat = nil
	if c.find_category(name).nil?
	  c.add_category(self, Model::Category.new(name))
	  puts "#{name} created"
	else
	  puts "#{name} already exists"
	end
	c.dirty
      end

      def self.delete(book, args, hargs)
	puts "\nDelete Category"
	c = book.company
	name = extract_arg(:name, 'Name', args, hargs)
	cat = book.company.find_category(name)
	if cat.nil?
	  puts "'#{name}' does not exist"
	elsif c.cat_used?(name)
	  puts "'#{name}' still in use"
	else
	  c.cat_del(name)
	  puts "'#{name}' deleted"
	end
	c.dirty
      end

    end
  end
end
