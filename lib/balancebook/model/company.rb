# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model
    class Company

      attr_accessor :name
      attr_accessor :accounts
      attr_accessor :customers
      attr_accessor :invoices
      attr_accessor :ledger
      attr_accessor :taxes
      attr_accessor :start

      def reports
	BalanceBook::Report::Reports.new(self)
      end

      def find_tax(id)
	id = id.downcase
	@taxes.each { |tax|
	  return tax if id == tax.id.downcase
	}
	nil
      end

      def find_customer(id)
	id = id.downcase
	@customers.each { |c|
	  return c if id == c.id.downcase || id == c.name.downcase
	}
	nil
      end

    end # Company
  end # Model
end # BalanceBook
