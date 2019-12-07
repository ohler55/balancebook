# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Transfer < Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :from     # account
      attr_accessor :to       # account
      attr_accessor :from_tx  # from transaction
      attr_accessor :to_tx    # to transaction
      attr_accessor :sent     # amount in from currecny
      attr_accessor :received # amount in to currecny
      attr_accessor :note

      def initialize(id)
	@id = id
      end

      def prepare(book, company)
	# TBD from, to, date
      end

      def validate(book)
	validate_date('Transaction date', @date)

	# TBD accounts, tx, amounts positive

      end

      def fx_loss(book, currency=nil)
	# TBD find currency for each, if same then return 0.0
	#   if different then calc based on target
	#   if currency is not nil then convert loss to currency provided
      end

    end
  end
end
