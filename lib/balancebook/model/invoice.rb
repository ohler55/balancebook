# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Invoice < Base

      attr_accessor :id
      attr_accessor :submitted
      attr_accessor :amount
      attr_accessor :to
      attr_accessor :po
      attr_accessor :payments
      attr_accessor :taxes # TaxAmount array
      attr_accessor :withheld
      attr_accessor :refunds # ledger entries as keys and amount as value (a Hash)
      attr_accessor :currency
      attr_accessor :is_penalty
      attr_accessor :_book
      attr_accessor :_company

      def prepare(book, company)
	@_book = book
	@_company = company
	@payments = [] if @payments.nil?
      end

      def validate(book)
	raise StandardError.new("Invoice ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Invoice amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	validate_date('Invoice submitted date', @submitted)
	cust = book.company.find_corporation(@to)
	raise StandardError.new("Customer #{@to} for invoice #{@id} not found.") if cust.nil?
	@to = cust.id
	raise StandardError.new("Invoice #{@id} over paid #{@amount} < #{paid_amount}.") if @amount < paid_amount
	unless @taxes.nil?
	  @taxes.each { |ta|
	    tax = book.company.find_tax(ta.tax)
	    raise StandardError.new("Invoice tax #{ta.tax} not found.") if tax.nil?
	    ta.tax = tax.id
	  }
	end
      end

      def submit_date
	Date.parse(@submitted)
      rescue Exception => e
	nil
      end

      def tax(kind=nil)
	return 0.0 if @taxes.nil?
	sum = 0.0
	@taxes.each { |ta| sum += ta.amount if kind.nil? || kind == ta.tax }
	sum.round(2)
      end

      def gross
	@amount
      end

      def income
	@amount - @withheld.to_f
      end

      # Most recent payment.
      def paid_date
	recent = nil
	@payments.each { |lid|
	  lx = @_company.find_entry(lid)
	  pd = Date.parse(lx.date)
	  recent = pd if recent.nil? || recent < pd
	}
	recent
      rescue Exception => e
	nil
      end

      def paid(full=true)
	recent = nil
	sum = 0.0
	@payments.each { |lid|
	  lx = @_company.find_entry(lid)
	  pd = Date.parse(lx.date)
	  recent = pd if recent.nil? || recent < pd
	  sum += lx.amount
	}
	recent = nil unless !full || @amount == sum
	recent
      end

      def paid_in_full
	@amount <= paid_amount
      end

      def paid_amount
	return 0.0 if @payments.nil?
	sum = 0.0
	@payments.each { |lid|
	  lx = @_company.find_entry(lid)
	  sum += lx.amount
	}
	sum
      end

      def paid_amount_by(date)
	return 0.0 if @payments.nil?
	sum = 0.0
	@payments.each { |p|
	  lx = @_company.find_entry(p)
	  pd = Date.parse(lx.date)
	  sum += lx.amount if pd <= date
	}
	sum
      end

      def days_to_paid
	t0 = submit_date.to_time.to_i
	pt = Date.parse(paid).to_time.to_i
	return nil if pt.nil?
	((pt - t0) / 86400).to_i
      end

      def pay(lx)
	@payments = [] if @payments.nil?
	@payments << lx
      end

      def days_late(as_of=nil)
	as_of = Date.today if as_of.nil?
	return nil if 0.0 < paid_amount_by(as_of)
	#return nil if paid_in_full
	t0 = submit_date.to_time.to_i
	t1 = as_of.to_time.to_i
	days = ((t1 - t0) / 86400).to_i
	return nil if days <= 45
	days
      end

      def penalty(as_of=nil)
	days = days_late(as_of)
	return nil if days.nil?

	day_rate = 0.015 * 12 / 365 # 1.5% per month
	day_rate * days * @amount
      end

      def amount_in_currency(base_cur)
	return @amount if @currency == base_cur
	base_rate = _book.fx.find_rate(base_cur, @submitted)
	inv_rate = _book.fx.find_rate(@currency, @submitted)
	(@amount * base_rate / inv_rate).round(2)
      end

      def income_in_currency(base_cur)
	return income if @currency == base_cur
	base_rate = _book.fx.find_rate(base_cur, @submitted)
	inv_rate = _book.fx.find_rate(@currency, @submitted)
	(income * base_rate / inv_rate).round(2)
      end

    end
  end
end
