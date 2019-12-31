# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class CurCol < Col
      def initialize(label, width, format, book, cur)
	super(label, width, nil, format)
	@cur = cur
	@book = book
      end

      def value(obj)
	obj.amount_in_currency(@book, @cur)
      end

      def to_s(obj, pad=true)
	return @label if obj.nil?
	return '' if obj.amount.nil?
	return @cur if obj.account.nil?
	super
      end
    end

    class Ledger
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete a ledger entry', {'id' => 'ID of entry to delete.'}),
	  Help.new('list', nil, 'List ledger entries.', {
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'reverse' => 'Reverse the order of the entries',
		     'missing' => 'Display only entries missing a matching account transaction',
		   }),
	  Help.new('new', ['create'], 'Create a new account.', {
		     'date' => 'Date the entry occurred',
		     'who' => 'Description of the entry or who it was paid to',
		     'cat' => 'Category of the entry',
		     'account' => 'Account name or ID',
		     'amount' => 'Total amount in the account currency',
		     'tip' => 'Amount of tip if applicable',
		     'tax' => 'Tax that was applied, e.g, HST',
		     'file' => 'Receipt or related file',
		     'note' => 'Additional information about the entry',
		   }),
	  Help.new('show', ['details'], 'Show ledger entry details.', {'id' => 'ID of ledger entry to display.'}),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'delete', 'del', 'rm'
	  #delete(book, args[1..-1], hargs)
	when 'list'
	  list(book, args[1..-1], hargs)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	when 'show'
	  show(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Ledger can not #{verb}.")
	end
      end

      def self.cmd_choices
	HELP.map { |h| h.name }
      end

      def self.list(book, args, hargs)
	period = extract_period(book, hargs)
	# TBD filter params like status, category, etc
	cur = book.fx.base # TBD look in hargs
	tsv = hargs.has_key?(:tsv)
	csv = hargs.has_key?(:csv)
	rev = hargs.has_key?(:reverse)
	miss = hargs.has_key?(:missing)

	table = Table.new('Ledger', [
			  Col.new('ID', 6, :id, "%d"),
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -1, :who, nil),
			  Col.new('Category', -1, :category, nil),
			  Col.new('Account', -1, :account, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  CurCol.new("Amount #{cur}", 10, '%.2f', book, cur),
			  Col.new('Transaction', -1, :acct_tx, nil),
			  Col.new('File', -1, :file, nil),
			  ])
	total = 0.0
	book.company.ledger.each { |e|
	  d = Date.parse(e.date)
	  next unless period.in_range(d)
	  next if miss && !e.acct_tx.nil? && !e.file.nil?
	  # TBD filters
	  table.add_row(e)
	  total += e.amount_in_currency(book, cur)
	}
	table.rows.reverse! unless rev
	table.add_row(Model::Entry.new(nil))
	# Add balance line
	e = Model::Entry.new(nil)
	e.who = 'Total'
	e.amount = total
	table.add_row(e)
	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display
	end
      end

      def self.create(book, args, hargs)
	puts "\nEnter information for a new Ledger Entry"
	id = book.company.gen_tx_id
	model = Model::Entry.new(id)
	model.date = hargs[:date] || read_date('Date')
	model.who = hargs[:who] || read_str('Who')
	model.category = hargs[:cat] || read_str('Category', book.company.categories.map { |c| c.name })
	cat = book.company.find_category(model.category)
	raise StandardError.new("Entry category #{model.category} not found.") if cat.nil?

	model.account = hargs[:account] ||
			read_str('Account', book.company.accounts.map { |a| a.id } + book.company.accounts.map { |a| a.name })
	acct = book.company.find_account(model.account)
	raise StandardError.new("Entry account #{@account} not found.") if acct.nil?

	model.amount = hargs[:amount] || read_amount('Amount')
	model.amount= model.amount.to_f
	raise StandardError.new("Entry amount #{model.amount} can not be zero.") if 0.0 == model.amount

	model.tip = hargs[:tip] || read_amount('Tip')
	model.tip = model.tip.to_f

	choices = book.company.taxes.map { |t| t.id }
	(hargs[:tax] || read_str('Taxes', choices)).split(',').each { |tax|
	  tax.strip!
	  next if 0 == tax.size
	  t = book.company.find_tax(tax)
	  raise StandardError.new("Entry tax #{@tax} not found.") if t.nil?
	  ta = Model::TaxAmount.new(t.id, (model.amount - model.tip) * t.percent / (100.0 + t.percent))
	  model.taxes = [] if model.taxes.nil?
	  model.taxes << ta
	}
	filenames = Dir.glob(File.dirname(book.data_file) + "/{files,invoices}/**/*").map { |p| File.file?(p) ? File.basename(p) : nil }
	filenames.delete_if { |m| m.nil? }
	model.file = hargs[:file] || read_str('File', filenames)
	model.file = nil if 0 == model.file.size
	unless '-' == model.file || model.file.nil?
	  raise StandardError.new("#{model.file} not found.") unless filenames.include?(model.file)
	end
	model.note = hargs[:note] || read_str('Note')
	model.note = nil if 0 == model.note.size
	model.tip = nil if 0.0 == model.tip
	model.validate(book)
	book.company.add_entry(book, model)
	puts "\n#{model.class.to_s.split('::')[-1]} #{model.id} added.\n\n"
	book.company.dirty
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.accounts.map { |a| a.id } + c.accounts.map { |a| a.name })
	entry = c.find_entry(id.to_i)
	raise StandardError.new("Failed to find ledger entry #{id}.") if entry.nil?
	puts "\n#{UNDERLINE}Ledger Entry #{entry.id}#{' ' * (67 - entry.id.size)}#{NORMAL}"
	puts "Date:        #{entry.date}"
	puts "Description: #{entry.who}"
	puts "Category:    #{entry.category}"
	puts "Account:     #{entry.account}"
	puts "Amount:      #{entry.amount}"
	puts "Tip:         #{entry.tip}" unless entry.tip.nil? || 0.0 == entry.tip
	unless entry.taxes.nil?
	  taxes = entry.taxes.map { |ta| "#{ta.tax} #{ta.amount}" }.join(', ')
	  puts "Tax:         #{taxes}"
	end
	puts "File:        #{entry.file}" unless entry.file.nil? || 0 == entry.file.size
	puts "Link:        #{entry.acct_tx}" unless entry.acct_tx.nil?
	puts "Note:        #{entry.note}" unless entry.note.nil? || 0 == entry.note.size
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
