# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Input

    class Invoice

      attr_accessor :model

      def initialize
	puts "\nEnter information for a new Invoice"
	@model = BalanceBook::Model::Invoice.new({})
	@model.id = read_str('ID')
	@model.submitted = read_date('Submitted')
	@model.amount = read_amount('Amount')
	@model.to = read_str('To')
      end

      def read_str(label)
	print("#{label}: ")
	STDIN.readline.strip
      end

      def read_date(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	Date.parse(v) # just to verify
	v
      end

      def read_amount(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

    end # Invoice
  end # Input
end # BalanceBook
