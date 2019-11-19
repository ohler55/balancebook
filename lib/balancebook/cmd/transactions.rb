# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transactions
      extend Base

      def self.list(book, args={})
	first, last = extract_date_range(book, args)
	name = args[:id]
	acct = book.company.find_account(name)
	raise StandardError.new("Failed to find account #{name}.") if acct.nil?

	table = Table.new("#{acct.name} Transactions (#{acct.currency})", [
			  Col.new('Date', -10, :date, nil),
			  Col.new('Description', -40, :who, nil),
			  Col.new('Amount', 10, :amount, '%.2f'),
			  ])

	acct.transactions.each { |t|
	  d = Date.parse(t.date)
	  next if d < first || last < d
	  table.add_row(t)
	}
	table.display
      end

    end
  end
end
