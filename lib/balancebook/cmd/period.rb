# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Period
      attr_accessor :first
      attr_accessor :last

      def in_range(date)
	first <= date && date <= last
      end

    end
  end
end
