# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model
    class Company

      attr_accessor :name
      attr_accessor :accounts
      attr_accessor :customers
      attr_accessor :invoices
      attr_accessor :ledger


      def initialize(h)
	@name = h['name']
	@accounts = h['accounts']
	@customers = h['customers']
	@invoices = h['invoices']
	@ledger = h['ledger']
      end

      def self.json_create(h)
	self.new(h)
      end

    end # Company
  end # Model
end # BalanceBook
