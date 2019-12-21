# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'io/console'

require 'oterm'

module BalanceBook
  module Cmd

    module Base

      def help
	puts "#{to_s.split('::')[-1]} commands:"
	help_cmds.each { |h| h.show }
      end

      def extract_arg(id, label, args, hargs, choices=[])
	return args[0] if !args.nil? && 0 < args.size && !args[0].include?('=')
	hargs[id] || read_str(label, choices)
      end

      def extract_period(book, args)
	p = args[:period]
	if p.nil?
	  period = Period.new
	  period.first = extract_first(book, args)
	  period.last = extract_last(book, args)
	  period
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
	period = Period.new
	year = p[0..3].to_i
	if 4 < p.size
	  raise StandardError.new("Invalid period '#{p}'.") if 'q' != p[4].downcase
	  case p[5].to_i
	  when 1
	    period.first = Date.new(year, 1, 1)
	    period.last = Date.new(year, 3, 31)
	  when 2
	    period.first = Date.new(year, 4, 1)
	    period.last = Date.new(year, 6, 30)
	  when 3
	    period.first = Date.new(year, 7, 1)
	    period.last = Date.new(year, 9, 30)
	  when 4
	    period.first = Date.new(year, 10, 1)
	    period.last = Date.new(year, 12, 31)
	  else
	    raise StandardError.new("Invalid period '#{p}'.")
	  end
	else
	  period.first = Date.new(year, 1, 1)
	  period.last = Date.new(year, 12, 31)
	end
	today = Date.today
	period.last = today if today < period.last
	period
      end

      def read_str(label, choices=[])
	vt = OTerm::VT100.new(IO.console)
	vt.instance_variable_set('@is_vt100', true)
	choices.sort!
	pos = 0
	val = ''
	print("#{label}: ")
	c = nil
	while true
	  prev = c
	  c = vt.con.getch
	  case c
	  when "\n", "\r"
	    break
	  when "\x7f" # delete key
	    next if pos <= 0
	    pos -= 1
	    if pos < val.size
	      val = val[0...pos] + val[pos + 1..-1]
	    else
	      val = val[0...pos]
	    end
	    vt.left(1)
	    vt.clear_to_end()
	    print(val[pos..-1] + ' ')
	    vt.left(val.size - pos)
	  when "\x01" # ^a
	    if 0 < pos
	      vt.left(pos)
	      pos = 0
	    end
	  when "\x02" # ^b
	    if 0 < pos
	      vt.left(1)
	      pos -= 1
	    end
	  when "\x03" # ^c
	    puts "\n-- cancelled --"
	    puts
	    Process.exit!(1)
	  when "\x04" # ^d
	    if pos < val.size
	      val = val[0...pos] + val[pos + 1..-1]
	      vt.clear_to_end()
	      print(val[pos..-1] + ' ')
	      vt.left(val.size - pos + 1)
	    end
	  when "\x05" # ^e
	    if pos < val.size
	      vt.right(val.size - pos)
	      pos = val.size
	    end
	  when "\x06" # ^f
	    if pos < val.size
	      vt.right(1)
	      pos += 1
	    end
	  when "\x0b" # ^k
	    if pos < val.size
	      val = val[0...pos]
	      vt.clear_to_end()
	    end
	  when "\t"
	    next if 0 == choices.size
	    if "\t" == prev
	      down = val.downcase
	      choices.each { |c|
		if c.downcase.start_with?(down)
		  vt.dim
		  print("\n  #{c}")
		  vt.attrs_off
		end
	      }
	      print("\n#{label}: #{val}")
	      next
	    end
	    found = []
	    down = val.downcase
	    choices.each { |c| found << c if c.downcase.start_with?(down) }
	    if 0 < found.size
	      best = found[0]
	      if 1 < found.size
		found[1..-1].each { |f|
		  best = common_start(best, f)
		}
	      end
	      vt.left(pos)
	      print(best)
	      val = best
	      pos = best.size
	    end
	  else
	    if ' ' <= c
	      if pos == val.size
		pos += 1
		val << c
		print(c)
	      else
		val.insert(pos, c)
		vt.clear_to_end()
		print(val[pos..-1])
		pos += 1
		vt.left(val.size - pos)
	      end
	    end
	  end
	end
	puts
	val.strip
      end

      def read_float(label)
	read_str(label).to_f
      end

      def read_date(label)
	v = read_str(label)
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
	read_str(label).to_f
      end

      def confirm(label)
	print("#{label}: ")
	return 'y' == STDIN.readline.strip
      end

      def common_start(a, b)
	a, b = b, a if b.size < a.size
	a.size.times { |i|
	  return a[0...i] if 0 != a[0..i].casecmp(b[0..i])
	}
	return a
      end

    end
  end
end
