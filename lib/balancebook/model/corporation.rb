# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Corporation

      attr_accessor :id
      attr_accessor :contacts
      attr_accessor :currency
      attr_accessor :address
      attr_accessor :notes

      def prepare(book, company)
      end

      def validate(book)
	raise StandardError.new("Corporation ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Corporation currency #{@currency} not found.") if book.fx.find_currency(@currency).nil?
	unless @contacts.nil?
	  @contacts.each { |c|
	    raise StandardError.new("Corporation contact #{@c.id} not found.") if book.company.find_contact(@c.id).nil?
	  }
	end
      end

      alias :name :id

    end
  end
end
