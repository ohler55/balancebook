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

      def self.help_cmds
	[
	  Help.new('update', nil, 'Update.', {
		     'id' => 'Ledger entry ID',
		     'file' => 'Receipt or related file',
		   }),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'update' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'update'
	  update(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Receipt can not #{verb}.")
	end
      end

      def self.update(book, args, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.ledger.map { |e| e.id.to_s })
	e = book.company.find_entry(id.to_i)
	raise StandardError.new("Failed to find ledger entry #{id}.") if e.nil?
	unless e.file.nil? || e.file.size == 0
	  return false unless confirm("Entry #{id} already has a receipt or file. Replace? [y|n]")
	end
	filenames = Dir.glob(File.dirname(book.data_file) + "/{files,invoices}/**/*").map { |p| File.file?(p) ? File.basename(p) : nil }
	filenames.delete_if { |m| m.nil? }
	e.file = hargs[:file] || read_str('File', filenames)
	e.file = nil if 0 == e.file.size
	unless '-' == e.file || e.file.nil?
	  raise StandardError.new("#{e.file} not found.") unless filenames.include?(e.file)
	end
	puts "\n#{e.class.to_s.split('::')[-1]} #{e.id} updated.\n\n"
	puts "#{Oj.dump(e, indent: 2)}" if book.verbose
	book.company.dirty
      end

    end
  end
end
