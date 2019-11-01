# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Invoice < Base

      attr_accessor :id
      attr_accessor :submitted
      attr_accessor :amount
      attr_accessor :to
      attr_accessor :payments
      attr_accessor :taxes # TaxAmount array

      def validate(book)
	raise StandardError.new("Invoice ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Invoice amount of #{@amount} must be greater than 0.0.") unless 0.0 < @amount
	validate_date('Invoice submitted date', @submitted)
	cust = book.company.find_customer(@to)
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

      def paid
	return nil if @payments.nil?
	pd = nil
	pt = nil
	@payments.each { |p|
	  next if p.date.nil?
	  t = Date.parse(p.date).to_time.to_i
	  if pt.nil? || pt < t
	    pt = t
	    pd = p.date
	  end
	}
	pd
      end

      def paid_amount
	return 0.0 if @payments.nil?
	sum = 0.0
	@payments.each { |p|
	  next if p.amount.nil?
	  sum += p.amount
	}
	sum
      end

      def days_to_paid
	return nil if @payments.nil?
	t0 = submit_date.to_time.to_i
	pt = Date.parse(paid).to_time.to_i
	return nil if pt.nil?
	((pt - t0) / 86400).to_i
      end

    end
  end
end
