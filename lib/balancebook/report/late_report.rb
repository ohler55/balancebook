# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Report

    class LateReport < Report

      def initialize(company)
	super('Late Invoice Payment Interest Calculations',
	      { id: 'Invoice',
		submitted: 'Submitted',
		amount: 'Amount',
		paid: 'Date Paid',
		d2p: 'Days Till Paid',
		interest: 'Interest',
	      },
	      [:id, :submitted, :amount, :paid, :d2p, :interest],
	      '%14s  %10s  %10s  %10s  %14s  %10s')

	@day_rate = 0.015 * 12 / 365 # 1.5% per month

	total = 0.0
	company.invoices.each { |inv|
	  pen = penalty(inv.amount, inv.days_to_paid)
	  total += pen
	  add_row({
		    id: inv.id,
		    submitted: inv.submitted,
		    amount: "$%0.2f" % [inv.amount],
		    paid: inv.paid,
		    d2p: inv.days_to_paid,
		    interest: "$%0.2f" % [pen],
		  })
	}
	add_row({
		  id: 'Total',
		  submitted: '',
		  amount: '',
		  paid: '',
		  d2p: '',
		  interest: "$%0.2f" % [total]
		})

      end

      def penalty(amount, days)
	return 0.0 if days.nil? || days < 90
	@day_rate * days * amount
      end

    end # LateReport
  end # Model
end # BalanceBook
