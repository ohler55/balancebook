# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Input

    class Invoice < Base

      attr_accessor :model

      def initialize(book, args)
	puts "\nEnter information for a new Invoice"
	@model = Model::Invoice.new
	@model.id = args[:id] || read_str('ID')
	@model.submitted = args[:submitted] || read_date('Submitted')
	@model.to = args[:to] || read_str('To')
	@model.amount = args[:amount] || read_amount('Amount')
	@model.amount= @model.amount.to_f
	tax = args[:tax] || read_str('Tax')
	if 0 < tax.size
	  ta = make_taxes(book, tax, @model.amount)
	  puts taxes.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	  @model.taxes = ta
	end
	@model.validate(book)
      end

      def make_taxes(book, tax_input, amount)
	ids = tax_input.split(',').map { |id| id.strip }

	return nil if 0 == ids[0].size
	taxes = []
	ids.each { |id|
	  tax = book.company.find_tax(id)
	  raise StandardError.new("Could not find #{id} tax.") if tax.nil?

	  # TBD broken for multiple taxes
	  ta = Model::TaxAmount.new(id, (amount * tax.percent / (tax.percent + 100.0) * 100.0).to_i / 100.0)
	  taxes << ta
	}
	taxes
      end

    end
  end
end
