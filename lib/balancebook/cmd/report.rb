# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

require 'balancebook/cmd/report_hst'

module BalanceBook
  module Cmd

    class Report

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

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'help' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'hst'
	  ReportHST.report(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Report can not #{verb}.")
	end
      end

    end
  end
end
