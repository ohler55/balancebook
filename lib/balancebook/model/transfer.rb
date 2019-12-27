# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Transfer < Base

      attr_accessor :id
      attr_accessor :date
      attr_accessor :from        # from account
      attr_accessor :to          # to account
      attr_accessor :from_tx     # from transaction
      attr_accessor :to_tx       # to transaction
      attr_accessor :ledger_loss # ledger entry for FX loss
      attr_accessor :fx_loss        # FX loss
      attr_accessor :note
      attr_accessor :_from
      attr_accessor :_to
      attr_accessor :_from_tx
      attr_accessor :_to_tx
      attr_accessor :_date

      def initialize(id)
	@id = id
      end

      def prepare(book, company)
	@_from = book.company.find_account(@from)
	@_to = book.company.find_account(@to)
	@_date = Date.parse(@date)
	@_from_tx = @_from.find_trans(@from_tx) unless @_from.nil?
	@_to_tx = @_to.find_trans(@to_tx) unless @_to.nil?
      end

      def validate(book)
	validate_date('Transaction date', @date)

	# TBD accounts, tx, amounts positive

      end

      def sent
	-@_from_tx.amount
      end

      def received
	@_to_tx.amount
      end

    end
  end
end
