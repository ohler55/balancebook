# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

require 'balancebook/cmd/report_hst'
require 'balancebook/cmd/report_income'
require 'balancebook/cmd/report_balance'

module BalanceBook
  module Cmd

    class Report
      extend Base

      def self.help_cmds
	[
	  Help.new('hst', nil, 'HST paid and owed', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'reverse' => 'Reverse the order of the entries',
		   }),
	  Help.new('income', nil, 'income statement', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'parens' => 'Parenthesis for negative amounts'
		   }),
	  Help.new('balance', nil, 'balance sheet', {
		     'period' => 'Period to match e.g., 2019q3, 2019',
		     'first' => 'First date to match',
		     'last' => 'Last date to match',
		     'csv' => 'Display output as CSV',
		     'tsv' => 'Display output as TSV',
		     'parens' => 'Parenthesis for negative amounts'
		   }),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'help' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'hst'
	  ReportHST.report(book, args[1..-1], hargs)
	when 'income'
	  ReportIncome.report(book, args[1..-1], hargs)
	when 'balance'
	  ReportBalance.report(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Report can not #{verb}.")
	end
      end

    end
  end
end
