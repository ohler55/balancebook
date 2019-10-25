# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Cmd

      def self.extract_date_range(book, args)
	p = args[:period]
	if p.nil?
	  [extract_first(book, args), extract_last(book, args)]
	else
	  parse_period(p)
	end
      end

      def self.extract_first(book, args)
	early = args[:first]
	if early.nil?
	  Date.parse(book.company.start)
	else
	  Date.parse(early)
	end
      end

      def self.extract_last(book, args)
	last = args[:last]
	if last.nil?
	  Date.today
	else
	  Date.parse(last)
	end
      end

      def self.parse_period(p)
	year = p[0..3].to_i
	if 4 < p.size
	  raise StandardError.new("Invalid period '#{p}'.") if 'q' != p[4].downcase
	  case p[5].to_i
	  when 1
	    first = Date.new(year, 1, 1)
	    last = Date.new(year, 3, 31)
	  when 2
	    first = Date.new(year, 4, 1)
	    last = Date.new(year, 6, 30)
	  when 3
	    first = Date.new(year, 7, 1)
	    last = Date.new(year, 9, 30)
	  when 4
	    first = Date.new(year, 10, 1)
	    last = Date.new(year, 12, 31)
	  else
	    raise StandardError.new("Invalid period '#{p}'.")
	  end
	else
	  first = Date.new(year, 1, 1)
	  last = Date.new(year, 12, 31)
	end
	today = Date.today
	last = today if today < last
	[first, last]
      end

    end
  end
end
