# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class Links
      extend Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :who
      attr_accessor :amount
      attr_accessor :account
      attr_accessor :link

      def initialize(e)
	@id = e.id
	@date = e.date
	@who = e.who
	@amount = e.amount
	@account = e.account
	@link = e.acct_tx
	@link = 'N/A' if @link.is_a?(String) && '-' == @link
      end

      def self.report(book, args={})
	period = extract_period(book, args)
	miss = args.has_key?(:missing)
	tsv = args.has_key?(:tsv)
	csv = args.has_key?(:csv)

	table = Table.new("Links (#{period.first} to #{period.last})", [
			  Col.new('ID', 6, :id, '%d'),
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -30, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  Col.new('Account', -10, :account, nil),
			  Col.new('Link', -20, :link, nil),
			  ])
	book.company.ledger.each { |e|
	  date = Date.parse(e.date)
	  next unless period.in_range(date)
	  next if miss && !e.acct_tx.nil?
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
	changed = nil
	period = extract_period(book, args)
	cash = args.has_key?(:cash)

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
	      changed = 'Ledger Links'
	      break
	    end
	  }
	  next if !cash || Model::Account::CASH != acct.kind
	  match = acct.make_cash_trans(e.date, e.amount, e.who)
	  link(e, match)
	  puts "Linked ledger #{e.id} to created #{acct.id}:#{match.id}" if book.verbose
	  changed = 'Ledger Links'
	}
	changed
      end

      def self.link(e, t)
	e.acct_tx = t.id
	t.ledger_tx = e.id
      end

    end
  end
end
