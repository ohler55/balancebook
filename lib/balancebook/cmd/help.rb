# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Cmd

    class Help
      attr_accessor :name
      attr_accessor :aliases
      attr_accessor :args
      attr_accessor :text

      def initialize(name, aliases, text, args)
	@name = name
	@aliases = aliases
	@text = text
	@args = args
      end

      def show(newline=true)
	puts "  #{BOLD}%-14s#{NORMAL} %s" % [@name, @text]
	@aliases.each { |a| puts "  #{BOLD}#{a}#{NORMAL}" } unless @aliases.nil?
	unless @args.nil?
	  @args.each { |arg|
	    puts "    #{BOLD}%-12s#{NORMAL} %s" % arg
	  }
	end
	puts if newline
      end

    end
  end
end
