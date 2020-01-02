# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class ReportBase
      extend Base

      attr_accessor :date

      def self.help_cmds
	[
	  Help.new(name, nil, description, {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'reverse' => 'Reverse the order of the entries',
		   }),
	]
      end

    end
  end
end
