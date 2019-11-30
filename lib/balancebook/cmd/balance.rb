# coding: utf-8
# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'csv'

require 'ox'

module BalanceBook
  module Cmd

    class Balance
      attr_accessor :label
      attr_accessor :balance
      attr_accessor :base_balance
      attr_accessor :currency

      def initialize(label, currency)
	@label = label
	@balance = 0.0
	@base_balance = 0.0
	@currency = currency
      end


    end
  end
end
