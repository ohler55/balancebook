# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Currency

      attr_accessor :id
      attr_accessor :rates

      def sort
	@rates.sort_by! { |r| r.date }
	@rates.reverse!
      end

      def rate(date)
	date = date.to_s
	# TBD divide and conquer using ratio of diff from first and last
	@rates.each { |r|
	  return r.rate if date == r.date
	}
	0.0
      end

    end
  end
end
