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

      def show(book, args={})
	p = args[:period]
	if p.nil?
	  first = extract_earliest(args)
	  last = extract_last(args)
	else
	  first, last = parse_period(p)
	end
	puts "\nForeign Exchange Rate (base: #{@base})"
	fmt = "%10s" + " %10.6f" * @currencies.size
	puts 'Date              ' + @currencies.map { |c| c.id }.join('        ')

	first.step(last, 1) { |d|
	  ds = d.to_s
	  vals = [ds]
	  @currencies.each { |c|
	    vals << c.rate(ds)
	  }
	  puts fmt % vals
	}
      end

      def extract_first(args)
	first = args[:start]
	if first.nil?
	  first = Date.new(2017, 1, 1)
	  @currencies.each { |c|
	    c.rates.each { |r|
	      d = Date.parse(r.date)
	      first = d if first < d
	    }
	  }
	else
	  first = Date.parse(first)
	end
	first
      end

      def extract_earliest(args)
	early = args[:start]
	if early.nil?
	  early = Date.new(2017, 1, 1)
	  @currencies.each { |c|
	    c.rates.each { |r|
	      d = Date.parse(r.date)
	      early = d if d < early
	    }
	  }
	else
	  early = Date.parse(early)
	end
	early
      end

      def extract_last(args)
	last = args[:end]
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

    end
  end
end
