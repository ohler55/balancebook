# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class Reports

      attr_accessor :book

      def initialize(book)
	@book = book
      end

      def penalty(args={})
	PenaltyReport.new(@book, args)
      end

    end
  end
end
