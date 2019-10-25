# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Input

    class Invoice

      attr_accessor :model

      def initialize(book)
	puts "\nEnter information for a new Invoice"
	@model = Model::Invoice.new
	@model.id = read_str('ID')
	@model.submitted = read_date('Submitted')
	@model.to = read_str('To')
	@model.amount = read_amount('Amount')
	@model.taxes = read_taxes(book, 'Tax', @model.amount)
      end

      def read_str(label)
	print("#{label}: ")
	STDIN.readline.strip
      end

      def read_date(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	if 0 < v.size
	  Date.parse(v) # just to verify
	else
	  v = Date.today.to_s
	end
	v
      end

      def read_amount(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

      def read_taxes(book, label, amount)
	print("#{label}: ")
	ids = STDIN.readline.split(',').map { |id| id.strip }

	return nil if 0 == ids[0].size
	taxes = []
	ids.each { |id|
	  tax = book.company.find_tax(id)
	  raise StandardError.new("Could not find #{id} tax.") if tax.nil?

	  # TBD broken for multiple taxes
	  ta = Model::TaxAmount.new(id, (amount * tax.percent / (tax.percent + 100.0) * 100.0).to_i / 100.0)
	  taxes << ta
	}
	puts taxes.map { |ta| "  %s: %0.2f" % [ta.tax, ta.amount] }.join('  ') if $verbose
	taxes
      end

    end
  end
end
