# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Rate < Base

      attr_accessor :date
      attr_accessor :rate

      def initialize(d, r)
	@date = d
	@rate = r
      end

      def validate(book)
	raise StandardError.new("FX rate #{@rate} must be greater than 0.0.") unless 0.0 < @rate
	validate_date('FX rate date', @date)
      end

    end
  end
end
