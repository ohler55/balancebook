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
	@taxes.each { |tax|
	  return tax if id == tax.id
	}
	nil
      end

    end # Company
  end # Model
end # BalanceBook
