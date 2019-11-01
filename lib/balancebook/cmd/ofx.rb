# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class OFX

      def self.parse(s)
	top = {}
	stack = [top]
	s.each_line { |line|
	  line.strip!
	  next if line.size == 0 || '<' != line[0]
	  if line.start_with?('</')
	    stack.shift
	  elsif '>' == line[-1] # group
	    name = line[1..-2]
	    parent = stack[0]
	    obj = {}
	    current = parent[name]
	    if current.nil?
	      parent[name] = obj
	    elsif current.is_a?(Array)
	      current << obj
	    else
	      parent[name] = [current, obj]
	    end
	    stack.unshift(obj)
	  else
	    key, val = line[1..-1].split('>', 2)
	    stack[0][key] = val
	  end
	}
	top
      end

    end
  end
end
