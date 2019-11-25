# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

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
	model.tip = args[:tip] || read_amount('Tip')
	model.tip= model.tip.to_f

	model.account = args[:account] || read_str('Account')
	acct = book.company.find_account(model.account)
	raise StandardError.new("Entry account #{@account} not found.") if acct.nil?
	(args[:tax] || read_str('Taxes')).split(',').each { |tax|
	  tax.strip!
	  next if 0 == tax.size
	  t = book.company.find_tax(tax)
	  raise StandardError.new("Entry tax #{@tax} not found.") if t.nil?
	  ta = Model::TaxAmount.new(t.id, (model.amount - model.tip) * t.percent / (100.0 + t.percent))
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
	entry = book.company.find_entry(id.to_i)
	raise StandardError.new("Failed to find ledger entry #{id}.") if entry.nil?
	puts "\nLedger Entry #{entry.id}"
	puts "Date: #{entry.date}"
	puts "Description: #{entry.who}"
	puts "Category: #{entry.category}"
	puts "Account: #{entry.account}"
	puts "Amount: #{entry.amount}"
	puts "Tip: #{entry.tip}" unless entry.tip.nil? || 0.0 == entry.tip
	unless entry.taxes.nil?
	  taxes = entry.taxes.map { |ta| "#{ta.tax} #{ta.amount}" }.join(', ')
	  puts "Tax: #{taxes}"
	end
	puts "File: #{entry.file}" unless entry.file.nil? || 0 == entry.file.size
	puts "Link: #{entry.acctTrans}" unless entry.acctTrans.nil?
	puts "Note: #{entry.note}" unless entry.note.nil? || 0 == entry.note.size
	puts
      end

      def self.import(book, args={})
	puts "\nImport Ledger Entries from CSV file"
	cat_map = {
	  "Computer – Internet" => 'Internet',
	  "Computer – Hardware" => 'Computer Hardware',
	  "Computer – Hosting" => 'Hosting',
	  "Insurance – General Liability" => 'Liability Insurance',
	  "Meals and Entertainment" => 'Entertainment',
	  "Owner Investment / Drawings" => 'Owner',
	  "Payroll – Salary & Wages" => 'Payroll Salary',
	  "Payroll – Tax Fed Employee FICA Medicare" => 'Payroll USA Employee FICA',
	  "Payroll – Tax Fed Employee SS" => 'Payroll USA Employee SS',
	  "Payroll – Tax Fed Employee WH" => 'Payroll USA Employee WH',
	  "Payroll – Tax Fed FICA - Medicare" => 'Payroll USA Corp FICA',
	  "Payroll – Tax Fed FICA - SS" => 'Payroll USA Corp SS',
	  "Payroll – Tax State ETT" => 'Payroll State ETT',
	  "Payroll – Tax State PIT" => 'Payroll State PIT',
	  "Payroll – Tax State SDI" => 'Payroll State SDI',
	  "Payroll – Tax State UI" => 'Payroll State UI',
	  "Telephone – Wireless" => 'Phone',
	  "Transfer" => 'Bank Transfer',
	  "Travel Business - Lodging" => 'Lodging',
	  "Travel Business - Meals" => 'Meals',
	  "Travel Business - Transportation" => 'Transportation',
	  "Travel Expense - Per Diem" => 'Per Diem',
	}
	acct_map = { 'USD' => 'bw', 'CAD' => 'scotiabank' }

	filename = args[:file] || read_str('File')
	changed = false

	Encoding.default_external = 'UTF-8'
	CSV.foreach(File.expand_path(filename), headers: true) { |row|
	  id = book.company.gen_tx_id
	  entry = Model::Entry.new(id)
	  entry.date = row.fetch('date')
	  entry.who = row.fetch('who')
	  entry.currency = row.fetch('currency')
	  entry.category = row.fetch('category')
	  debit = row.fetch('debit')
	  credit = row.fetch('credit')
	  if credit.nil?
	    entry.amount = -debit.to_f
	  else
	    entry.amount = credit.to_f
	  end
	  entry.category = cat_map[entry.category] unless cat_map[entry.category].nil?
	  entry.account = acct_map[entry.currency]
	  book.company.add_entry(book, entry)
	  changed = true
	}
	changed
      end

    end
  end
end
