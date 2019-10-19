# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Invoice

      attr_accessor :id
      attr_accessor :submitted
      attr_accessor :amount
      attr_accessor :to
      attr_accessor :payments

      def initialize(h)
	@id = h['id']
	@submitted = h['submitted']
	@amount = h['amount']
	@to = h['to']
	@payments = h['payments']
      end

      def self.json_create(h)
	self.new(h)
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
	  next if p.when.nil?
	  t = Date.parse(p.when).to_time.to_i
	  if pt.nil? || pt < t
	    pt = t
	    pd = p.when
	  end
	}
	pd
      end

      def days_to_paid
	return nil if @payments.nil?
	t0 = submit_date.to_time.to_i
	pt = Date.parse(paid).to_time.to_i
	return nil if pt.nil?
	((pt - t0) / 86400).to_i
      end

    end # Invoice
  end # Model
end # BalanceBook
