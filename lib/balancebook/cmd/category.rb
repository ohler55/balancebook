# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Category
      extend Base

      def self.list(book, args={})
	table = Table.new('Categories', [
			  Col.new('Name', -30, :name, nil),
			  ])

	table.rows = book.company.categories
	table.display
      end

      def self.create(book, args={})
	puts "\nCreate Category"
	name = args[:name] || read_str('Name')
	cat = nil
	if book.company.find_category(name).nil?
	  cat = Model::Category.new(name)
	  puts "#{name} created"
	else
	  puts "#{name} already exists"
	end
	cat
      end

      def self.delete(book, args={})
	puts "\nDelete Category"
	deleted = false
	name = args[:name] || read_str('Name')
	cat = book.company.find_category(name)
	if cat.nil?
	  puts "'#{name}' does not exist"
	elsif book.company.cat_used?(name)
	  puts "'#{name}' still in use"
	else
	  book.company.cat_del(name)
	  deleted = true
	  puts "'#{name}' deleted"
	end
	deleted
      end

    end
  end
end
