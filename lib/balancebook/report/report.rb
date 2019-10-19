# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class Report

      attr_accessor :title
      attr_accessor :header

      # TBD add sort key(s)

      def initialize(title, header, order, format)
	@title = title
	@order = order   # array of keys in display order
	@format = format
	@header = header # map of key-labels
	@rows = []
      end

      def add_row(row)
	@rows << row
      end

      def display
	puts
	puts @title
	puts
	line = []
	@order.each { |k| line << @header[k] }
	puts @format % line
	@rows.each { |row|
	  line = []
	  @order.each { |k| line << row[k] }
	  puts @format % line
	}
      end

      def csv(f)
	@order.each { |k| f.write(@header[k]+',') }
	f.puts
	@rows.each { |row|
	  @order.each { |k| f.write(row[k].to_s+',') }
	  f.puts
	}
      end

    end # Report
  end # Model
end # BalanceBook
