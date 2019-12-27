# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transfer
      extend Base

      def self.help_cmds
	[
	  Help.new('delete', ['del', 'rm'], 'Delete an transfer', {'id' => 'ID of transfer to delete.'}),
	  Help.new('list', nil, 'List transfers.', {
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		   }),
	  Help.new('new', ['create'], 'Create a new transfer.', {
		     'from' => 'ID or Name of the source account',
		     'to' => 'ID or Name of the destination account',
		     'from_tx' => 'ID of transaction from the source account',
		     'to_tx' => 'ID of transaction from the destination account',
		     'note' => 'Optional note',
		   }),
	  Help.new('show', ['details'], 'Show transfer details.', {'id' => 'ID of transfer to display.'}),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'delete', 'del', 'rm'
	  delete(book, args, hargs)
	when 'list'
	  list(book, args[1..-1], hargs)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	when 'show'
	  show(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Transfer can not #{verb}.")
	end
      end

      def self.list(book, args, hargs)
	period = extract_period(book, hargs)

	table = Table.new("Transfers", [
			    Col.new('Date', -10, :date, nil),
			    Col.new('From', -10, :from, nil),
			    Col.new('To', -10, :to, nil),
			    Col.new('Sent', 10, :sent, '%.2f'),
			    Col.new('Received', 10, :received, '%.2f'),
			    Col.new('FX Loss', 10, :fx_loss, '%.2f'),
			    # TBD show transactions and ledger entries if details option
			  ])

	book.company.transfers.each { |t|
	  d = Date.parse(t.date)
	  next unless period.in_range(d)
	  table.add_row(t)
	}
	table.display
      end

      def self.create(book, args, hargs)
	puts "\nEnter information for a new Transfer"
	id = book.company.gen_transfer_id
	xfer = Model::Transfer.new(id)
	xfer.date = extract_date(:date, 'Date', args, hargs)

	# TBD move extract_account to base
	accounts = book.company.accounts.map { |a| a.id } + book.company.accounts.map { |a| a.name }
	xfer.from = extract_arg(:from, 'From', args, hargs, accounts)
	from = book.company.find_account(xfer.from)
	raise StandardError.new("From account #{xfer.from} not found.") if from.nil?

	xfer.to = extract_arg(:to, 'To', args, hargs, accounts)
	to = book.company.find_account(xfer.to)
	raise StandardError.new("To account #{xfer.to} not found.") if to.nil?

	sent = extract_amount(:sent, 'Sent Amount', args, hargs)
	raise StandardError.new("Sent amount #{sent} can not be zero.") if 0.0 == sent

	received = extract_amount(:received, 'Received Amount', args, hargs)
	raise StandardError.new("Received amount #{received} can not be zero.") if 0.0 == received

	choices = from.transactions.select { |t|
	  # TBD check for within 10 days or something
	  sent == -t.amount
	}.map { |t| t.id }
	xfer.from_tx = extract_arg(:from_tx, 'From Transaction', args, hargs, choices)
	raise StandardError.new("From transaction #{xfer.from}:#{xfer.from_tx} not found.") unless choices.include?(xfer.from_tx)
	from_tx = from.find_trans(xfer.from_tx)

	choices = to.transactions.select { |t| received == t.amount }.map { |t| t.id }
	xfer.to_tx = extract_arg(:to_tx, 'To Transaction', args, hargs, choices)
	unless choices.include?(xfer.to_tx)
	  if Model::Account::CASH == to.kind && (xfer.to_tx.nil? || 0 == xfer.to_tx.size)
	    tx = to.make_cash_trans(xfer.date, sent, 'transfer')
	    xfer.to_tx = tx.id
	    puts "Transaction #{to.name}:#{tx.id} (#{tx.amount})."
	  else
	    raise StandardError.new("To transaction #{xfer.to}:#{xfer.to_tx} not found.")
	  end
	end
	to_tx = to.find_trans(xfer.to_tx)

	xfer.note = extract_arg(:note, 'Note', args, hargs, accounts)
	xfer.note = nil if 0 == xfer.note.size
	xfer.validate(book)

	if from_tx.ledger_tx.nil?
	  id = book.company.gen_tx_id
	  entry = Model::Entry.new(id)
	  entry.date = xfer.date
	  entry.amount = from_tx.amount
	  entry.who = "Transfer to #{to.name}"
	  entry.account = from.id
	  entry.category = 'Bank Transfer'
	  entry.acct_tx = xfer.from_tx
	  entry.file = '-'
	  from_tx.ledger_tx = id
	  book.company.add_entry(book, entry)
	  puts "Ledger Entry #{entry.id} added for #{from.name}:#{entry.acct_tx} (#{entry.amount})."
	else
	  puts "Ledger Entry #{from_tx.ledger_tx} found for #{from.name}:#{from_tx.ledger_tx} (#{from_tx.amount})."
	end

	if to_tx.ledger_tx.nil?
	  id = book.company.gen_tx_id
	  entry = Model::Entry.new(id)
	  entry.date = xfer.date
	  entry.amount = to_tx.amount
	  entry.who = "Transfer from #{from.name}"
	  entry.account = to.id
	  entry.category = 'Bank Transfer'
	  entry.acct_tx = xfer.to_tx
	  entry.file = '-'
	  to_tx.ledger_tx = id
	  book.company.add_entry(book, entry)
	  puts "Ledger Entry #{entry.id} added for #{to.name}:#{entry.acct_tx} (#{entry.amount})."
	else
	  puts "Ledger Entry #{to_tx.ledger_tx} found for #{to.name}:#{to_tx.ledger_tx} (#{to_tx.amount})."
	end

	book.company.add_transfer(book, xfer)
	book.company.dirty

	return if from.currency == to.currency

	from_cur = from._currency
	to_cur = to._currency
	from_rate = from_cur.rate(xfer.date)
	to_rate = to_cur.rate(xfer.date)
	want = (sent * to_rate / from_rate).round(2)
	loss = (want - received).round(2)
	xfer.fx_loss = loss

	la_id = "FX-Loss-#{to_cur.id}"
	loss_acct = book.company.find_account(la_id)
	if loss_acct.nil?
	  loss_acct = Model::Account.new(la_id)
	  loss_acct.name = la_id
	  loss_acct.kind = Model::Account::FX_LOSS
	  loss_acct.currency = to_cur.id
	  loss_acct._currency = to_cur
	  loss_acct._company = book.company
	  loss_acct.transactions = []
	  book.company.add_account(book, loss_acct)
	  puts "Account #{loss_acct.name} added."
	end
	entry = nil
	loss_tx = nil
	loss_acct.transactions.each { |t|
	  if t.date == xfer.date && t.amount == -loss
	    loss_tx = t
	    break
	  end
	}
	if loss_tx.nil?
	  loss_tx = loss_acct.make_fx_loss_trans(xfer.date, -loss, xfer.id)
	  puts "Transaction #{loss_acct.name}:#{loss_tx.id} (#{loss_tx.amount}) added."
	end
	if loss_tx.ledger_tx.nil?
	  id = book.company.gen_tx_id
	  entry = Model::Entry.new(id)
	  entry.date = xfer.date
	  entry.amount = -loss
	  entry.who = "Transfer #{sent} #{from_cur.id} from #{from.name} to #{to.name}"
	  entry.account = la_id
	  entry.category = 'Bank Transfer'
	  entry.acct_tx = loss_tx.id
	  entry.file = '-'
	  entry.note = "Foreign exchange loss. With #{from_cur.id} at #{from_rate.round(6)} and #{to_cur.id} at #{to_rate.round(6)} the received should be #{want}."
	  loss_tx.ledger_tx = entry.id
	  book.company.add_entry(book, entry)
	  puts "Ledger Entry #{entry.id} added for #{entry.account}:#{entry.acct_tx} (#{entry.amount})."
	end
      end

    end
  end
end
