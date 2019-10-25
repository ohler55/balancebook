# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Fx

      def self.show(book, args={})
	p = args[:period]
	if p.nil?
	  first = extract_earliest(args)
	  last = extract_last(args)
	else
	  first, last = parse_period(p)
	end
	puts "\nForeign Exchange Rate (base: #{book.fx.base})" if $verbose
	fmt = "%10s" + " %10.6f" * book.fx.currencies.size
	puts 'Date              ' + book.fx.currencies.map { |c| c.id }.join('        ')

	first.step(last, 1) { |d|
	  ds = d.to_s
	  vals = [ds]
	  book.fx.currencies.each { |c|
	    vals << c.rate(ds)
	  }
	  puts fmt % vals
	}
      end

    end
  end
end
