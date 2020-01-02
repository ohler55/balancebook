# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Account < Base

      CHECKING = 'CHECKING'
      SAVINGS  = 'SAVINGS'
      CASH     = 'CASH'

      FX_LOSS  = 'FX_LOSS'

      # TBD
      ASSET     = 'ASSET'     # Cash, Accounts Receivable, Supplies, Equipment
      LIABILITY = 'LIABILITY' # Notes Payable, Accounts Payable, Wages Payable
      EQUITY    = 'EQUITY'    # Common Stock, Retained Earnings
      REVENUE   = 'REVENUE'   # Service Revenues, Investment Revenues
      EXPENSE   = 'EXPENSE'   # Wages Expense, Rent Expense, Depreciation Expense

      attr_accessor :id
      attr_accessor :name
      attr_accessor :address
      attr_accessor :aba
      attr_accessor :kind
      attr_accessor :currency
      attr_accessor :transactions
      attr_accessor :_company
      attr_accessor :_currency

      def initialize(id)
	@id = id
	@transactions = []
      end

      def prepare(book, company)
	@_company = company
	@_currency = book.fx.find_currency(@currency)
	@transactions.each { |t| t.prepare(book, self) }
      end

      def validate(book)
	raise StandardError.new("Account ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Account name can not be empty.") unless !@name.nil? && 0 < @name.size
	raise StandardError.new("Account kind of '#{@kind}' is not valid.") unless [CHECKING, SAVINGS, CASH, FX_LOSS].include?(@kind)
	unless @transactions.nil?
	  dups = {}
	  @transactions.each { |t|
	    t.validate(book)
	    raise StandardError.new("Duplicate bank transaction #{id}-#{t.id}.") unless dups[t.id].nil?
	    dups[t.id] = t
	  }
	end
      end

      def add_trans(t)
	x = find_trans(t.id)
	return false unless x.nil?
	if @transactions.nil?
	  @transactions = [t]
	else
	  @transactions << t
	end
	sort_trans
	true
      end

      def sort_trans
	@transactions.sort! { |a,b|
	  dif = b.date <=> a.date
	  dif = a.id <=> b.id if 0 == dif
	  dif
	} unless @transactions.nil?
      end

      def find_trans(id)
	unless @transactions.nil?
	  @transactions.each { |t|
	    return t if id == t.id
	  }
	end
	nil
      end

      def match_trans(date, amount, margin=0)
	unless @transactions.nil?
	  @transactions.each { |t|
	    next unless t.ledger_tx.nil?
	    return t if date == t.date && amount == t.amount
	    if 0 < margin
	      d = Date.parse(date)
	      lo = d.prev_day(margin).to_s
	      hi = d.next_day(margin).to_s
	      return t if lo <= t.date && t.date <= hi && amount == t.amount
	    end
	  }
	end
	nil
      end

      def make_cash_trans(date, amount, desc)
	id = date.delete('-') + '01'
	97.times { |i|
	  break if find_trans(id).nil?
	  id = id[0..-3] + "%02d" % [i + 2]
	}
	t = Transaction.new(id, date, amount, desc)
	@transactions << t
	sort_trans
	t
      end

      # just used for cash accounts
      def make_fx_loss_trans(date, amount, xfer_id)
	pre = date.split('-').join('')
	tid = ''
	@transactions.size.times { |i|
	  tid = "%s%02d" % [pre, i]
	  break if find_trans(tid).nil?
	}
	t = Transaction.new(tid, date, amount, "loss from transfer #{xfer_id}")
	@transactions << t
	sort_trans
	t
      end

      def balance
	total = 0.0
	@transactions.each { |t| total += t.amount }
	total
      end

      def amount_in_currency(book, amount, base_cur, date)
	return amount if @currency == base_cur
	base_rate = book.fx.find_rate(base_cur, date)
	acct_rate = book.fx.find_rate(@currency, date)
	amount * base_rate / acct_rate
      end

      # If no date given then use the rate on the day of the transaction.
      def sum_in_currency(book, base_cur, period, date=nil, ledger_date=false)
	sum = 0.0
	if @currency == base_cur || !date.nil?
	  @transactions.each { |t|
	    if ledger_date && !t._ledger_date.nil?
	      d = t._ledger_date
	    else
	      d = Date.parse(t.date)
	    end
	    next unless period.in_range(d)
	    sum += t.amount
	  }
	  unless date.nil?
	    base_rate = book.fx.find_rate(base_cur, date)
	    acct_rate = book.fx.find_rate(@currency, date)
	    sum = sum * base_rate / acct_rate
	  end
	else
	  @transactions.each { |t|
	    if ledger_date && !t._ledger_date.nil?
	      d = t._ledger_date
	    else
	      d = Date.parse(t.date)
	    end
	    next unless period.in_range(d)
	    base_rate = book.fx.find_rate(base_cur, d)
	    acct_rate = book.fx.find_rate(@currency, d)
	    sum += (t.amount * base_rate / acct_rate).round(2)
	  }
	end
	sum
      end

    end
  end
end
