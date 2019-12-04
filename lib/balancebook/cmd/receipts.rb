# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class Receipts
      extend Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :who
      attr_accessor :category
      attr_accessor :amount
      attr_accessor :file

      def initialize(e)
	@id = e.id
	@date = e.date
	@category = e.category
	@who = e.who
	@amount = e.amount
	@file = e.file
	@file = 'N/A' if @file.is_a?(String) && '-' == @file
	# TBD get currency
      end

      def self.report(book, args={})
	period = extract_period(book, args)
	miss = args.has_key?(:missing)

	table = Table.new("Ledger Entries (#{period.first} to #{period.last})", [
			  Col.new('ID', 6, :id, '%d'),
			  Col.new('Date', -10, :date, nil),
			  Col.new('Category', -20, :category, nil),
			  Col.new('Description', -40, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Receipt', -60, :file, nil),
			  ])
	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next unless period.in_range(date)
	  next if miss && !e.file.nil? && 0 < e.file.size
	  table.add_row(new(e))
	}
	case args[:format] || args[:fmt]
	when 'tsv'
	  table.tsv
	when 'csv'
	  table.csv
	else
	  table.display
	end
      end

      def self.update(book, args={})
	id = args[:id] || read_str('ID')
	e = book.company.find_entry(id.to_i)
	raise StandardError.new("Failed to find ledger entry #{id}.") if e.nil?
	unless e.file.nil? || e.file.size == 0
	  return false unless confirm("Entry #{id} already has a receipt or file. Replace? [y|n]")
	end
	e.file = args[:file] || read_str('File')
	"Entry #{id}"
      end

    end
  end
end
