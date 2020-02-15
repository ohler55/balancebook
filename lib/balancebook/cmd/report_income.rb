# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

require 'balancebook/cmd/report_base'

module BalanceBook
  module Cmd

    class ReportIncome < ReportBase

      attr_accessor :cat

      def initialize(book=nil)
	# TBD
      end

      def self.report(book, args, hargs)
	period = extract_period(book, hargs)
	tsv = hargs.has_key?(:tsv)
	csv = hargs.has_key?(:csv)
	rev = hargs.has_key?(:reverse)

	table = Table.new("Income Statement from #{period.first} to #{period.last}", [

			  ])
	if tsv
	  table.tsv
	elsif csv
	  table.csv
	else
	  table.display
	end
      end

    end
  end
end
