# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Account < Base

      CHECKING = 'CHECKING'
      SAVINGS = 'SAVINGS'
      CASH = 'CASH'
      FX_LOSS = 'FX_LOSS'

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
	if x.nil?
	  if @transactions.nil?
	    @transactions = [t]
	  else
	    @transactions << t
	  end
	  sort_trans
	else
	  # TBD verify no changes
	end
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
	    # TBD leeway on date
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
	t
      end

      def make_fx_loss_trans(date, amount, xfer_id)
	t = Transaction.new(xfer_id, date, amount, "loss from transfer #{xfer_id}")
	@transactions << t
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


    end
  end
end
