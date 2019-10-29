# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model
    class Company < Base

      attr_accessor :name
      attr_accessor :accounts
      attr_accessor :customers
      attr_accessor :invoices
      attr_accessor :ledger
      attr_accessor :taxes
      attr_accessor :contacts
      attr_accessor :start

      def validate(book)
	validate_date('Company start date', @start)
	dups = {} # used for dup check on each type
	unless @accounts.nil?
	  dups = {}
	  @accounts.each { |a|
	    a.validate(book)
	    raise StandardError.new("Duplicate account #{a.id}.") unless dups[a.id].nil?
	    dups[a.id] = a
	  }
	end
	unless @customers.nil?
	  dups = {}
	  @customers.each { |c|
	    c.validate(book)
	    raise StandardError.new("Duplicate customer #{c.id}.") unless dups[c.id].nil?
	    dups[c.id] = c
	  }
	end
	unless @invoices.nil?
	  dups = {}
	  @invoices.each { |i|
	    i.validate(book)
	    raise StandardError.new("Duplicate invoice #{i.id}.") unless dups[i.id].nil?
	    dups[i.id] = i
	  }
	end
	unless @ledger.nil?
	  dups = {}
	  @ledger.each { |t|
	    t.validate(book)
	    raise StandardError.new("Duplicate ledger transaction #{t.id}.") unless dups[t.id].nil?
	    dups[t.id] = t
	  }
	end
	unless @taxes.nil?
	  dups = {}
	  @taxes.each { |t|
	    t.validate(book)
	    raise StandardError.new("Duplicate tax #{t.id}.") unless dups[t.id].nil?
	    dups[t.id] = t
	  }
	end
	unless @contacts.nil?
	  dups = {}
	  @contacts.each { |c|
	    c.validate(book)
	    raise StandardError.new("Duplicate contact #{c.id}.") unless dups[c.id].nil?
	    dups[c.id] = c
	  }
	end
      end

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

      def find_contact(id)
	id = id.downcase
	@contacts.each { |c|
	  return c if id == c.id.downcase
	}
	nil
      end

      def find_account(id)
	id = id.downcase
	@accounts.each { |a|
	  return a if id == a.id.downcase
	}
	nil
      end

      def find_trans(id)
	id = id.downcase
	@ledger.each { |t|
	  return t if id == t.id.downcase
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
