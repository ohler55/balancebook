# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Fx
      extend Base

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'show', 'list'
	  show(book, args[1..-1], hargs)
	when 'update'
	  update(book, args[1..-1], hargs)
	else
	  raise StandardError.new("FX can not #{verb}.")
	end
      end

      def self.show(book, args, hargs)
	period = extract_period(book, hargs)
	puts "\n#{BOLD}Foreign Exchange Rate (base: #{book.fx.base}) #{NORMAL}"
	fmt = "%10s" + "  %10.6f" * book.fx.currencies.size
	puts "#{UNDERLINE}Date      #{NORMAL}  #{UNDERLINE}       " +
	     book.fx.currencies.map { |c| c.id }.join("#{NORMAL}  #{UNDERLINE}       ") +
	     "#{NORMAL}"

	period.first.step(period.last, 1) { |d|
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

      def self.update(book, args, hargs)
	period = extract_period(book, hargs)
	period.first.step(period.last, 1) { |d|
	  u = book.fx_url.gsub('${date}', d.to_s)
	  need = false
	  book.fx.currencies.each { |c|
	    if 0.0 == c.rate(d)
	      need = true
	      break
	    end
	  }
	  next unless need
	  content = Net::HTTP.get(URI(u))
	  h = Oj.load(content)
	  raise StandardError.new(h.to_s) if h['success'] != true
	  ds = d.to_s
	  base_rate = h['rates'][book.fx.base].to_f
	  book.fx.currencies.each { |c|
	      r = h['rates'][c.id].to_f
	      rate = BalanceBook::Model::Rate.new(d.to_s, r / base_rate)
	      c.rates.delete_if { |x| x.date == ds }
	      c.rates << rate
	      puts "updated fx rate for #{c.id} on #{ds}" if $verbose
	    }
	}
	book.fx.currencies.each { |c| c.sort }
	book.fx.dirty
      end

    end
  end
end
