# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'net/http'

module BalanceBook
  module Model

    class Fx

      attr_accessor :base
      attr_accessor :currencies

      def update(book, args={})
	first = extract_first(args)
	last = extract_last(args)
	first.step(last, 1) { |d|
	  u = book.fx_url.gsub('${date}', d.to_s)
	  content = Net::HTTP.get(URI(u))
	  h = Oj.load(content)
	  raise StandardError.new(h.to_s) if h['success'] != true
	  ds = d.to_s
	  base_rate = h['rates'][@base].to_f
	  @currencies.each { |c|
	      r = h['rates'][c.id].to_f
	      rate = BalanceBook::Model::Rate.new(d.to_s, r / base_rate)
	      c.rates.delete_if { |x| x.date == ds }
	      c.rates << rate
	      puts "updated fx rate for #{c.id} on #{ds}" if $verbose
	    }
	}
	@currencies.each { |c| c.sort }
      end

    end
  end
end
