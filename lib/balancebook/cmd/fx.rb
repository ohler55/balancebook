# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Fx
      extend Base

      def self.show(book, args={})
	first, last = extract_date_range(book, args)

	puts "\nForeign Exchange Rate (base: #{book.fx.base})" if $verbose
	fmt = "%10s" + " %10.6f" * book.fx.currencies.size
	puts 'Date              ' + book.fx.currencies.map { |c| c.id }.join('        ')

	first.step(last, 1) { |d|
	  ds = d.to_s
	  vals = [ds]
	  present = false
	  book.fx.currencies.each { |c|
	    v = c.rate(ds)
	    vals << v
	    present = true if 0.0 < v
	  }
	  puts fmt % vals if present
	}
      end

    end
  end
end
