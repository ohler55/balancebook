# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'
require 'net/http'

module BalanceBook
  module Model

    class Fx

      attr_accessor :base
      attr_accessor :currencies

      def validate(book)
	raise StandardError.new("Fx base can not be empty.") unless !@base.nil? && 0 < @base.size
	@currencies.each { |c| c.validate(book) } unless @currencies.nil?
      end

      def find_currency(id)
	return Model::Currency.new(@base) if id == @base
	id = id.upcase
	@currencies.each { |c|
	  return c if c.id == id
	}
	nil
      end

    end
  end
end
