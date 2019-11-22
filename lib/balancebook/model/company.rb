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
      attr_accessor :categories

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

      def add_invoice(book, inv)
	raise StandardError.new("Duplicate invoice #{inv.id}.") unless find_invoice(inv.id).nil?
	inv.validate(book)
	@invoices << inv
	@invoices.sort_by! { |inv| inv.submitted }
      end

      def add_category(book, cat)
	raise StandardError.new("Duplicate category #{cat.name}.") unless find_category(cat.name).nil?
	@categories << cat
	@categories.sort_by! { |cat| cat.name }
      end

      def add_tax(book, tax)
	raise StandardError.new("Duplicate tax #{tax.id}.") unless find_tax(tax.id).nil?
	@taxes << tax
	@taxes.sort_by! { |tax| tax.id }
      end

      def add_tx(book, t)
	@ledger << t
	@ledger.sort_by! { |t| t.date }
      end

      def cat_used?(id)
	@ledger.each { |t|
	  return true if t.category == id
	}
	false
      end

      def tax_used?(id)
	@ledger.each { |t|
	  return true if t.tax == id
	}
	@invoices.each { |inv|
	  unless inv.taxes.nil?
	    inv.taxes.each { |ta|
	      return true if ta.tax == id
	    }
	  end
	}
	false
      end

      def cat_del(id)
	@categories.reject! { |cat| cat.name == id }
      end

      def tax_del(id)
	@taxes.reject! { |tax| tax.id == id }
      end

      # TBD put somewhere else
      def reports
	BalanceBook::Report::Reports.new(self)
      end

      def find_account(id)
	id = id.downcase
	@account.each { |acct|
	  return acct if id == acct.id.downcase
	}
	nil
      end

      def find_tax(id)
	id = id.downcase
	@taxes.each { |tax|
	  return tax if id == tax.id.downcase
	}
	nil
      end

      def find_category(id)
	id = id.downcase
	@categories.each { |cat|
	  return cat if id == cat.name.downcase
	}
	nil
      end

      def find_invoice(id)
	id = id.downcase
	@invoices.each { |inv|
	  return inv if id == inv.id.downcase
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
	@ledger.each { |t|
	  return t if id == t.id
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

      def gen_tx_id
	max = @ledger.size
	@ledger.each { |t|
	  max = t.id if max < t.id
	}
	max + 1
      end



    end # Company
  end # Model
end # BalanceBook
