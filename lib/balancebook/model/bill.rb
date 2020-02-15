# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Bill < Base

      attr_accessor :id # corp invoice ID, not unique
      attr_accessor :from
      attr_accessor :received
      attr_accessor :amount
      attr_accessor :payments
      attr_accessor :taxes # TaxAmount array
      attr_accessor :currency
      attr_accessor :file
      attr_accessor :_book
      attr_accessor :_company

      def prepare(book, company)
	@_book = book
	@_company = company
      end

      def validate(book)
	raise StandardError.new("Bill ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Bill amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	validate_date('Bill received date', @received)
	corp = book.company.find_corporation(@from)
	raise StandardError.new("Corporation #{@from} for bill #{@id} not found.") if corp.nil?
	@from = corp.id
	raise StandardError.new("Bill #{@id} over paid #{@amount} < #{paid_amount}.") if @amount < paid_amount
	unless @taxes.nil?
	  @taxes.each { |ta|
	    tax = book.company.find_tax(ta.tax)
	    raise StandardError.new("Bill tax #{ta.tax} not found.") if tax.nil?
	    ta.tax = tax.id
	  }
	end
      end

      def receive_date
	Date.parse(@received)
      rescue Exception => e
	nil
      end

      def tax(kind=nil)
	return 0.0 if @taxes.nil?
	sum = 0.0
	@taxes.each { |ta| sum += ta.amount if kind.nil? || kind == ta.tax }
	sum.round(2)
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

      def paid
	return nil if @payments.nil?
	recent = nil
	sum = 0.0
	@payments.each { |lid|
	  lx = @_company.find_entry(lid)
	  pd = Date.parse(lx.date)
	  recent = pd if recent.nil? || recent < pd
	  sum -= lx.amount
	}
	recent = nil unless @amount == sum
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
	  sum -= lx.amount
	}
	sum
      end

      def paid_amount_by(date)
	return 0.0 if @payments.nil?
	sum = 0.0
	@payments.each { |p|
	  lx = @_company.find_entry(p)
	  pd = Date.parse(lx.date)
	  sum -= lx.amount if pd <= date
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

    end
  end
end
