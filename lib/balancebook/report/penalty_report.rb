# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class PenaltyHeader

      def self.id; 'Invoice'; end

      def self.submitted
	'Submitted'
      end

      def self.amount
	'Amount'
      end

      def self.paid
	'Date Paid'
      end

      def self.daysTillPaid
	'Days Till Paid'
      end

      def self.interest
	'Interest'
      end

    end

    class PenaltyRow

      attr_accessor :id
      attr_accessor :submitted
      attr_accessor :amount
      attr_accessor :paid
      attr_accessor :daysTillPaid
      attr_accessor :interest

    end

    class PenaltyReport < Base

      def initialize(book, args={})
	super('Penalty Invoice Payment Interest Calculations',
	      PenaltyHeader, [:id, :submitted, :amount, :paid, :daysTillPaid, :interest])

	@day_rate = 0.015 * 12 / 365 # 1.5% per month

	total = 0.0
	book.company.invoices.each { |inv|
	  pen = penalty(inv.amount, inv.days_to_paid)
	  total += pen

	  row = PenaltyRow.new
	  row.id = inv.id
	  row.submitted = inv.submitted
	  row.amount = inv.amount
	  row.paid = inv.paid
	  row.daysTillPaid = inv.days_to_paid || -1
	  row.interest = pen
	  add_row(row)
	}
	row = PenaltyRow.new
	row.id = 'Total'
	row.interest = total
	add_row(row)

      end

      def penalty(amount, days)
	return 0.0 if days.nil? || days < 90
	@day_rate * days * amount
      end

    end
  end
end
