# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Rate

      attr_accessor :date
      attr_accessor :rate

      def initialize(d, r)
	@date = d
	@rate = r
      end

    end
  end
end
