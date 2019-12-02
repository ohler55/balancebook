# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'net/http'

module BalanceBook
  module Model

    class Fx

      attr_accessor :base
      attr_accessor :symbol
      attr_accessor :shift
      attr_accessor :currencies
      attr_accessor :_book

      def prepare(book)
	@_book = book
	@currencies.each { |c| c.prepare(book, self) }
      end

      def validate(book)
	raise StandardError.new("Fx base can not be empty.") unless !@base.nil? && 0 < @base.size
	@currencies.each { |c| c.validate(book) } unless @currencies.nil?
      end

      def find_currency(id)
	return Model::Currency.new(@base) if id == @base
	id = id.upcase
	@currencies.each { |c|
	  return c if c.id == id
	}
	nil
      end

      def find_rate(id, date)
	id.upcase!
	return 1.0 if id == @base
	cur = find_currency(id)
	raise StandardError.new("Currency %s not found.") if cur.nil?
	rate = cur.rate(date)
	raise StandardError.new("Currency %s not found.") if rate <= 0.0
	rate
      end

      def convert(src_cur, amount, dest_cur, date)
	# find rate for src and dest
	#
	src_rate = find_rate(src_cur, date)
	dest_rate = find_rate(dest_cur, date)
	amount * dest_rate / src_rate
      end

    end
  end
end
