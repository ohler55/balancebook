# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class Links
      extend Base

      def self.help_cmds
	[
	  Help.new('new', ['create'], 'Link a ledger entry to an account transaction.', {
		     'entry' => 'ID of one or more ledger entries',
		     'tx' => 'ID of an account transaction (can be blank for a cash account)',
		   }),
	  Help.new('match', nil, 'Match ledger entries and account transactions.', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'cash' => 'if true auto create cash transactions for cash accounts.'
		   }),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	when 'match'
	  match(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Link can not #{verb}.")
	end
      end

      def self.match(book, args, hargs)
	period = extract_period(book, hargs)
	cash = hargs.has_key?(:cash)

	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next unless period.in_range(date)
	  next unless e.acct_tx.nil?
	  acct = book.company.find_account(e.account)
	  raise StandardError.new("Failed to find account #{id}.") if acct.nil?

	  (0..5).each { |margin|
	    match = acct.match_trans(e.date, e.amount, margin)
	    unless match.nil?
	      link(e, match)
	      puts "Linked ledger #{e.id} to #{acct.id}:#{match.id} within #{margin} days" if book.verbose
	      book.company.dirty
	      break
	    end
	  }
	  next if !cash || Model::Account::CASH != acct.kind
	  match = acct.make_cash_trans(e.date, e.amount, e.who)
	  link(e, match)
	  puts "Linked ledger #{e.id} to created #{acct.id}:#{match.id}" if book.verbose
	  book.company.dirty
	}
      end

      def self.create(book, args, hargs)
	puts "\nEnter information for a ledger - transaction link"
	eids = hargs[:entry] || read_str('Entry IDs')
	entries = eids.split(',').map { |eid|
	  eid.strip!
	  entry = book.company.find_entry(eid)
	  raise StandardError.new("Failed to find ledger entry #{eid}.") if entry.nil?
	  entry
	}
	raise StandardError.new("At least one ledger entry is required.") unless 0 < entries.size
	acct = entries[0]._account
	sum = 0.0
	entries.each { |e|
	  sum += e.amount
	  raise StandardError.new("All ledger entries must be for the same account.") unless acct == e._account
	}
	tid = hargs[:tx] || read_str("#{acct.name} Transaction ID")
	tx = acct.find_trans(tid)
	if tx.nil?
	  if Model::Account::CASH == acct.kind
	    if 0 < entries.size
	      tx = acct.make_cash_trans(entries[0].date, sum, 'multiple ledger entries')
	    else
	      tx = acct.make_cash_trans(entries[0].date, sum, entries[0].who)
	    end
	  else
	    raise StandardError.new("Failed to find #{acct.name} transaction #{tid}.")
	  end
	end
	raise StandardError.new("Ledger amount #{sum} does not equal #{acct.name} amount of #{tx.amount}.") unless sum == tx.amount
	if 1 < entries.size
	  entries.each { |e| e.acct_tx = tx.id }
	  tx.ledger_tx = entries.map { |e| e.id }
	else
	  link(entries[0], tx)
	end
	puts "Linked ledger #{tx.id} to  #{acct.id}:#{entries.map { |e| e.id }.join(', ')}" if book.verbose
	book.company.dirty
      end

      def self.link(e, t)
	e.acct_tx = t.id
	t.ledger_tx = e.id
      end

    end
  end
end
