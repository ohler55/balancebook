# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Ledger
      extend Base

      def self.list(book, args={})
	first, last = extract_date_range(book, args)
	# TBD filter params like status, category, etc

	table = Table.new('Ledger', [
			  Col.new('ID', 6, :id, "%d"),
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -40, :who, nil),
			  Col.new('Category', -20, :category, nil),
			  Col.new('Account', -10, :account, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Cur', -3, :currency, nil),
			  Col.new('Tax', 10, :tax, '%.2f'),
			  Col.new('Link', -10, :acctTrans, nil),
			  ])

	book.company.ledger.each { |t|
	  d = Date.parse(t.date)
	  next if d < first || last < d
	  # TBD filters
	  table.add_row(t)
	}
	table.display
      end

      def self.create(book, args)
	puts "\nEnter information for a new Ledger Entry"
	id = book.company.gen_tx_id
	model = Model::Entry.new(id)
	model.date = args[:date] || read_date('Date')
	model.who = args[:who] || read_str('Who')
	model.category = args[:cat] || read_str('Category')
	cat = book.company.find_category(model.category)
	raise StandardError.new("Entry category #{model.category} not found.") if cat.nil?
	model.amount = args[:amount] || read_amount('Amount')
	model.amount= model.amount.to_f
	model.account = args[:account] || read_str('Account')
	acct = book.company.find_account(model.account)
	raise StandardError.new("Entry account #{@account} not found.") if acct.nil?
	model.currency = acct.currency
	(args[:tax] || read_str('Taxes')).split(',').each { |tax|
	  tax.strip!
	  next if 0 == tax.size
	  t = book.company.find_tax(tax)
	  raise StandardError.new("Entry tax #{@tax} not found.") if t.nil?
	  ta = Model::TaxAmount.new(t.id, model.amount * t.percent / (100.0 + t.percent))
	  model.taxes = [] if model.taxes.nil?
	  model.taxes << ta
	}
	model.file = args[:file] || read_str('File')
	# TBD verify file exists
	model.note = args[:note] || read_str('Note')
	model.validate(book)
	model
      end

      def self.show(book, args={})
	id = args[:id]
	trans = book.company.find_trans(id.to_i)
	raise StandardError.new("Failed to find ledger entry #{id}.") if trans.nil?
	puts "\nLedger Entry #{trans.id}"
	puts "Date: #{trans.date}"
	puts "Description: #{trans.who}"
	puts "Category: #{trans.category}"
	puts "Account: #{trans.account}"
	puts "Amount: #{trans.amount}"
	puts "Currency: #{trans.currency}"
	taxes = trans.taxes.map { |ta| "#{ta.tax} #{ta.amount}" }.join(', ')
	puts "Tax: #{taxes}"
	puts "File: #{trans.file}"
	puts "Link: #{trans.acctTrans}"
	puts "Note: #{trans.note}"
	puts
      end

    end
  end
end
