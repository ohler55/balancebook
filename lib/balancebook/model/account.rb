# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Account < Base

      CHECKING = 'CHECKING'
      SAVINGS = 'SAVINGS'
      CASH = 'CASH'

      attr_accessor :id
      attr_accessor :name
      attr_accessor :address
      attr_accessor :aba
      attr_accessor :kind
      attr_accessor :transactions

      def initialize(id)
	@id = id
      end

      def validate(book)
	raise StandardError.new("Account ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Account name can not be empty.") unless !@name.nil? && 0 < @name.size
	raise StandardError.new("Account #{@kind} is not a valid.") unless [CHECKING, SAVINGS, CASH].include?(@kind)
	unless @transactions.nil?
	  dups = {}
	  @transactions.each { |t|
	    t.validate(book)
	    raise StandardError.new("Duplicate bank transaction #{id}-#{t.id}.") unless dups[t.id].nil?
	    dups[t.id] = t
	  }
	end
      end

      def find_trans(id)
	unless @transactions.nil?
	  @transactions.each { |t|
	    return t if id == t.id
	  }
	end
	nil
      end

    end
  end
end
