# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class DateDiff
      extend Base

      attr_accessor :ledger
      attr_accessor :entry_date
      attr_accessor :who
      attr_accessor :account
      attr_accessor :amount
      attr_accessor :acct_trans
      attr_accessor :trans_date
      attr_accessor :diff
      attr_accessor :date # ledger date parsed
      attr_accessor :note

      def initialize(book, e)
	@ledger = e.id
	@entry_date = e.date
	@who = e.who
	@amount = e.amount
	@date = Date.parse(e.date)
	@account = e._account.name
	@acct_trans = e.acct_tx
	@note = e.note
	tx = e._account.find_trans(e.acct_tx)
	unless tx.nil?
	  @trans_date = tx.date
	  d = Date.parse(tx.date)
	  @diff = d - @date
	  @diff = -@diff if @diff < 0
	end
      end

      def self.help_cmds
	[
	  Help.new('list', nil, 'Display the difference in dates between ledger entries and account transactions.', {
		     'over' => 'Days over to display',
		     'period' => 'Period to display e.g., 2019q3, 2019',
		     'first' => 'First date to display',
		     'last' => 'Last date to display',
		     'reverse' => 'Reverse the order of the rows',
		   }),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'list'
	  list(book, args[1..-1], hargs)
	else
	  raise StandardError.new("DateDiff can not #{verb}.")
	end
      end

      def self.list(book, args, hargs)
	period = extract_period(book, hargs)
	over = extract_arg(:over, 'Over', args, hargs).to_i
	rev = hargs.has_key?(:reverse)
	table = Table.new('Date Differences', [
			  Col.new('Ledger', -1, :ledger, nil),
			  Col.new('Entry Date', -1, :entry_date, nil),
			  Col.new('Description', -1, :who, nil),
			  Col.new('Account', -1, :account, nil),
			  Col.new('Account Transaction', -1, :acct_trans, nil),
			  Col.new('Transaction Date', -1, :trans_date, nil),
			  Col.new('Diff', 1, :diff, '%d'),
			  Col.new('Amount', 1, :amount, '%0.2f'),
			  Col.new('Note', -1, :note, nil),
			  ])
	table.rows = []
	book.company.ledger.each { |e|
	  row = new(book, e)
	  next unless period.in_range(row.date)
	  next if !row.diff.nil? && row.diff < over
	  table.add_row(row)
	}
	table.rows.reverse! unless rev

	table.display
      end

    end
  end
end
