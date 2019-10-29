# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class Base

      attr_accessor :title
      attr_accessor :header
      attr_accessor :rows

      # TBD add sort key(s)

      def initialize(title, header, order)
	@title = title
	@order = order   # array of keys in display order
	@header = header # map of key-labels
	@rows = []
      end

      def add_row(row)
	@rows << row
      end

      def value_width(v)
	value_str(v).size
      end

      def value_str(v)
	return '' if v.nil?
	case v
	when Float
	  fmt = '%0.2f'
	when Integer
	  fmt = '%d'
	else
	  fmt = '%s'
	end
	fmt % [v]
      end

      def display
	# calculate column widths
	widths = {}
	total = 0
	@order.each { |k|
	  max = 0
	  v = @header.send(k)
	  w = v.size
	  max = w if max < w
	  @rows.each { |row|
	    v = row.send(k)
	    w = value_width(v)
	    max = w if max < w
	  }
	  widths[k] = max
	  total += max
	}
	total += widths.size * 2 - 2
	# now print
	puts
	puts "#{' ' * ((total - @title.size) / 2)}#{@title}"
	puts
	line = []
	@order.each { |k|
	  w = widths[k]
	  v = value_str(@header.send(k))
	  v += ' ' * (w - v.size)
	  line << v
	}
	puts line.join('  ')

	@rows.each { |row|
	  line = []
	  @order.each { |k|
	    w = widths[k]
	    v = row.send(k)
	    s = value_str(v)
	    if v.is_a?(Numeric)
	      s = ' ' * (w - s.size) + s
	    else
	      s += ' ' * (w - s.size)
	    end
	    line << s
	  }
	  puts line.join('  ')
	}
      end

      def csv(f)
	@order.each { |k| f.write(@header.send(k)+',') }
	f.puts
	@rows.each { |row|
	  @order.each { |k| f.write(row.send(k).to_s+',') }
	  f.puts
	}
      end

    end # Report
  end # Model
end # BalanceBook
