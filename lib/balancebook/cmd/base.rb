# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    module Base

      def extract_date_range(book, args)
	p = args[:period]
	if p.nil?
	  [extract_first(book, args), extract_last(book, args)]
	else
	  parse_period(p)
	end
      end

      def extract_first(book, args)
	early = args[:first]
	if early.nil?
	  Date.parse(book.company.start)
	else
	  Date.parse(early)
	end
      end

      def extract_last(book, args)
	last = args[:last]
	if last.nil?
	  Date.today
	else
	  Date.parse(last)
	end
      end

      def parse_period(p)
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

      def read_str(label)
	print("#{label}: ")
	STDIN.readline.strip
      end

      def read_date(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	if 0 < v.size
	  unless /^(19|20)\d\d[-.](0[1-9]|1[012])[-.](0[1-9]|[12][0-9]|3[01])$/.match?(date.to_s)
	    raise StandardError.new("#{where} of #{date} did not match format YYY-MM-DD.")
	  end
	else
	  v = Date.today.to_s
	end
	v
      end

      def read_amount(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

      def read_float(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

      def read_date(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	if 0 < v.size
	  unless /^(19|20)\d\d[-.](0[1-9]|1[012])[-.](0[1-9]|[12][0-9]|3[01])$/.match?(v)
	    raise StandardError.new("#{v} did not match format YYYY-MM-DD.")
	  end
	else
	  v = Date.today.to_s
	end
	v
      end

      def read_amount(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

    end
  end
end
