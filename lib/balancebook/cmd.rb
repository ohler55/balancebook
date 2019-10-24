# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Cmd

    def self.run(verb, type, args={})
      case verb
      when 'new'
	puts "*** new #{type} #{args}"
      when 'show'
	puts "*** show #{type} #{args}"
      when 'update'
	puts "*** update #{type} #{args}"
      when 'del'
	puts "*** del #{type} #{args}"
      when 'list'
	puts "*** list #{type} #{args}"
      when 'report'
	# TBD args are filters with a headers="foo,bar" cols="id,name"
	puts "*** report #{type} #{args}"
      else
	raise StandardError.new("#{verb} is not a valid command.")
      end
    end
  end
end
