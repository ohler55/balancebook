# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class Reports

      def initialize(company)
	@company = company
      end

      def late(args={})
	LateReport.new(@company, args)
      end

    end # Report
  end # Model
end # BalanceBook
