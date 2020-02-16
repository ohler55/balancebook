# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'balancebook/cmd/report_hst'
require 'balancebook/cmd/report_income'
require 'balancebook/cmd/report_balance'

module BalanceBook
  module Cmd

    class Report
      extend Base

      def self.help_cmds
	ReportHST.help_cmds +
	  ReportIncome.help_cmds +
	  ReportBalance.help_cmds
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
