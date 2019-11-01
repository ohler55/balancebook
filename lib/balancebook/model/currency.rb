# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Currency

      attr_accessor :id
      attr_accessor :rates

      def initialize(id)
	@id = id
      end

      def validate(book)
	raise StandardError.new("Currency ID can not be empty.") unless !@id.nil? && 0 < @id.size
	@rates.each { |r| r.validate(book) } unless @rates.nil?
      end

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
