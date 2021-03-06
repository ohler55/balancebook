# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model
    class Company < Base

      attr_accessor :name
      attr_accessor :accounts
      attr_accessor :corporations
      attr_accessor :invoices
      attr_accessor :bills
      attr_accessor :ledger
      attr_accessor :taxes
      attr_accessor :contacts
      attr_accessor :start
      attr_accessor :categories
      attr_accessor :transfers
      attr_accessor :_book

      attr_accessor :_dirty

      def prepare(book)
	@_book = book
	@accounts.each { |a| a.prepare(book, self) }
	@corporations.each { |c| c.prepare(book, self) }
	@bills.each { |bill| bill.prepare(book, self) }
	@invoices.each { |inv| inv.prepare(book, self) }
	@ledger.each { |e| e.prepare(book, self) }
	@transfers.each { |t| t.prepare(book, self) }
	@_dirty = false
      end

      def dirty
	@_dirty = true
      end

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
	unless @corporations.nil?
	  dups = {}
	  @corporations.each { |c|
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
	  @ledger.each { |e|
	    e.validate(book)
	    raise StandardError.new("Duplicate ledger entry #{e.id}.") unless dups[e.id].nil?
	    dups[e.id] = e
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
	unless @transfers.nil?
	  # TBD check for duplicates
	  @transfers.each { |t|
	    t.validate(book)
	  }
	end
      end

      def add_account(book, acct)
	raise StandardError.new("Duplicate account #{acct.id}.") unless find_account(acct.id).nil?
	acct.validate(book)
	@accounts << acct
	@accounts.sort! { |a,b| a.id <=> b.id }
      end

      def add_invoice(book, inv)
	raise StandardError.new("Duplicate invoice #{inv.id}.") unless find_invoice(inv.id).nil?
	inv.validate(book)
	@invoices << inv
	@invoices.sort! { |a,b|
	  b.id <=> a.id if b.submitted == a.submitted
	  b.submitted <=> a.submitted
	}
      end

      def add_bill(book, bill)
	raise StandardError.new("Duplicate bill #{bill.from} - #{bill.id}.") unless find_bill(bill.from, bill.id).nil?
	bill.validate(book)
	@bills = [] if @bills.nil?
	@bills << bill
	@bills.sort! { |a,b| b.received <=> a.received }
      end

      def add_category(book, cat)
	raise StandardError.new("Duplicate category #{cat.name}.") unless find_category(cat.name).nil?
	@categories << cat
	@categories.sort_by! { |cat| cat.name }
      end

      def add_corporation(corp)
	raise StandardError.new("Duplicate corporation #{corp.name}.") unless find_corporation(corp.name).nil?
	@corporations << corp
	@corporations.sort_by! { |c| c.name }
      end

      def add_tax(book, tax)
	raise StandardError.new("Duplicate tax #{tax.id}.") unless find_tax(tax.id).nil?
	@taxes << tax
	@taxes.sort_by! { |tax| tax.id }
      end

      def add_entry(book, e)
	# TBD check for duplicates
	begin
	  e.validate(book)
	rescue Exception => x
	  raise x.exception("#{Oj.dump(e, mode: :custom, indent: 0)}\n#{x.message}")
	end
	@ledger << e
	@ledger.sort! { |a,b|
	  dif = (b.date <=> a.date)
	  dif = (b.id <=> a.id) if 0 == dif
	  dif
	}
      end

      def add_transfer(book, t)
	t.validate(book)
	@transfers = [] if @transfers.nil?
	@transfers << t
	@transfers.sort! { |a,b| b.date <=> a.date }
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

      def find_account(id)
	return nil if @accounts.nil?
	id = id.downcase
	@accounts.each { |acct|
	  return acct if id == acct.id.downcase || id == acct.name.downcase
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

      def find_bill(from, id)
	return nil if @bills.nil?
	id = id.downcase
	@bills.each { |bill|
	  return bill if from == bill.from && id == bill.id.downcase
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

      def find_entry(id)
	id = id.to_i
	@ledger.each { |e|
	  return e if id == e.id
	}
	nil
      end

      def find_corporation(id)
	id = id.downcase
	@corporations.each { |c|
	  return c if id == c.id.downcase || id == c.name.downcase
	}
	nil
      end

      def find_transfer(id)
	id = -id if id < 0
	@transfers.each { |xfer|
	  return xfer if id == xfer.id
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

      def gen_transfer_id
	max = @transfers.size
	@transfers.each { |t|
	  max = t.id if max < t.id
	}
	max + 1
      end

    end # Company
  end # Model
end # BalanceBook
