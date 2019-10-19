# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Payment

      attr_accessor :account
      attr_accessor :when
      attr_accessor :amount

      def initialize(h)
	@account = h['account']
	@when = h['when']
	@amount = h['amount']
      end

      def self.json_create(h)
	self.new(h)
      end

    end # Payment
  end # Model
end # BalanceBook
