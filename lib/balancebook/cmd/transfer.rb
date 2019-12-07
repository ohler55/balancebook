# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transfer
      extend Base

      def self.list(book, args={})
	period = extract_period(book, args)

	table = Table.new("Transfers", [
			  Col.new('Date', -10, :date, nil),
			  Col.new('From', -10, :from, nil),
			  Col.new('To', -10, :to, nil),
			  Col.new('Sent', 10, :sent, '%.2f'),
			  Col.new('Received', 10, :received, '%.2f'),
			  Col.new('Note', -60, :note, nil),
			  ])

	book.company.transfers.each { |t|
	  d = Date.parse(t.date)
	  next unless period.in_range(d)
	  table.add_row(t)
	}
	table.display
      end

      def self.create(book, args)
	puts "\nEnter information for a new Transfer"
	id = book.company.gen_transfer_id
	xfer = Model::Transfer.new(id)
	xfer.date = args[:date] || read_date('Date')

	# TBD move extract_account to base
	accounts = book.company.accounts.map { |a| a.id } + book.company.accounts.map { |a| a.name }
	xfer.from = args[:from] || read_str('From', accounts)
	from = book.company.find_account(xfer.from)
	raise StandardError.new("From account #{xfer.from} not found.") if from.nil?

	xfer.to = args[:to] || read_str('To', accounts)
	to = book.company.find_account(xfer.to)
	raise StandardError.new("To account #{xfer.to} not found.") if to.nil?

	choices = from.transactions.map { |t| t.id }
	xfer.from_tx = args[:from_tx] || read_str('From Transaction', choices)
	raise StandardError.new("From transaction #{xfer.from}:#{xfer.from_tx} not found.") unless choices.include?(xfer.from_tx)

	choices = to.transactions.map { |t| t.id }
	xfer.to_tx = args[:to_tx] || read_str('To Transaction', choices)
	raise StandardError.new("To transaction #{xfer.to}:#{xfer.to_tx} not found.") unless choices.include?(xfer.to_tx)

	xfer.sent = args[:sent] || read_amount('Sent Amount')
	xfer.sent= xfer.sent.to_f
	raise StandardError.new("Sent amount #{xfer.sent} can not be zero.") if 0.0 == xfer.sent

	xfer.received = args[:received] || read_amount('Received Amount')
	xfer.received= xfer.received.to_f
	raise StandardError.new("Received amount #{xfer.received} can not be zero.") if 0.0 == xfer.received

	xfer.note = args[:note] || read_str('Note')
	xfer.note = nil if 0 == xfer.note.size
	xfer.validate(book)

	from_cur = from._currency
	to_cur = to._currency
	from_rate = from_cur.rate(xfer.date)
	to_rate = to_cur.rate(xfer.date)
	want = (xfer.sent * to_rate / from_rate).round(2)
	loss = want - xfer.received

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
	end
	loss_acct.make_fx_loss_trans(xfer.date, -loss, xfer.id)

	id = book.company.gen_tx_id
	entry = Model::Entry.new(id)
	entry.date = xfer.date
	entry.amount = -loss
	entry.who = "Transfer #{xfer.sent} #{from_cur.id} from #{from.name} to #{to.name}"
	entry.account = la_id
	entry.category = 'Bank Transfer'
	entry.acct_tx = xfer.id
	entry.file = '-'
	entry.note = "Foreign exchange loss. With #{from_cur.id} at #{from_rate.round(6)} and #{to_cur.id} at #{to_rate.round(6)} the received should be #{want}."

	[xfer, entry]
      end

    end
  end
end
