# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

module BalanceBook
  module Cmd

    class Col
      LEFT = -1
      CENTER = 0
      RIGHT = 1

      attr_accessor :label
      attr_accessor :width
      attr_accessor :just
      attr_accessor :format
      attr_accessor :method

      def initialize(label, width, method, format)
	@label = label
	if 0 < width
	  @width = width
	  @just = RIGHT
	else
	  @width = -width
	  @just = LEFT
	end
	@method = method
	@format = format
      end

      def to_s(obj)
	if obj.nil?
	  s = @label
	else
	  v = obj.send(method)
	  if @format.nil?
	    s = v.to_s
	  else
	    s = @format % [v]
	  end
	end
	if s.size < @width
	  case @just
	  when LEFT
	    s += ' ' * (@width - s.size)
	  when RIGHT
	    s =  ' ' * (@width - s.size) + s
	  else
	    s += ' ' * ((@width - s.size) / 2)
	    s =  ' ' * (@width - s.size) + s
	  end
	end
	s
      end
    end

    class Table
      BOLD = "\x1b[1m"
      NORMAL = "\x1b[m"
      UNDERLINE = "\x1b[4m"

      attr_accessor :title
      attr_accessor :cols
      attr_accessor :rows

      def initialize(title, cols=[])
	@title = title
	@cols = cols
	@rows = []
      end

      def add_row(obj)
	@rows << obj
      end


      def display
	puts "\n#{BOLD}#{@title}#{NORMAL}"
	@cols.each_with_index { |col,i|
	  print('  ') unless 0 == i
	  print("#{UNDERLINE}#{col.to_s(nil)}#{NORMAL}")
	}
	puts
	@rows.each { |row|
	  @cols.each_with_index { |col,i|
	    print('  ') unless 0 == i
	    print(col.to_s(row))
	  }
	  puts
	}
	puts
      end

      def csv
	# TBD
      end

    end
  end
end
