# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Transfer
      extend Base

      def self.list(book, args={})
	first, last = extract_date_range(book, args)

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
	  next if d < first || last < d
	  table.add_row(t)
	}
	table.display
      end

    end
  end
end
