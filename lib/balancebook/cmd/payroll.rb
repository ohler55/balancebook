# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Payroll
      extend Base

      class TaxRate
	attr_accessor :min
	attr_accessor :max
	attr_accessor :plus
	attr_accessor :percent

	def initialize(min, max, plus, percent)
	  @min = min
	  @max = max
	  @plus = plus
	  @percent = percent
	end
      end

      def self.help_cmds
	[
	  Help.new('show', nil, 'Calculate payroll amounts given a target corporate gross.', {
		     'gross' => 'Corposrate gross amount',
		   }),
	]
      end

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'show' if verb.nil? || verb.include?('=')
	case verb
	when 'help', '?'
	  help
	when 'show'
	  show(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Payroll can not #{verb}.")
	end
      end

      def self.show(book, args, hargs)
	gross = extract_amount(:gross, 'Gross', args, hargs)
	salary = gross / (1 + 0.062 + 0.0145)

	puts "Payroll for a gross corporate expanse of %0.2f" % [gross]
	puts "Employee Gross Salary:    %10.2f" % [salary]
	puts
	puts "Federal Withholding:      %10.2f" % [fed_wh(salary)]
	puts "Company Social Security:  %10.2f" % [(salary * 0.062).round(2)]
	puts "Company Medicare:         %10.2f" % [(salary * 0.0145).round(2)]
	puts "Employee Social Security: %10.2f" % [(salary * 0.062).round(2)]
	puts "Employee Medicare:        %10.2f" % [(salary * 0.0145).round(2)]
	puts
	puts "California PIT:           %10.2f" % [edd_pit(salary)]
	puts "California UI:            %10.2f" % [edd_ui(salary)]
	puts "California SDI:           %10.2f" % [edd_sdi(salary)]
	puts "California ETT:           %10.2f" % [edd_ett(salary)]
	puts
	puts "After Taxes:              %10.2f" % [after_taxes(salary)]
	puts
      end

      def self.after_taxes(salary)
	salary -
	  fed_wh(salary) -
	  (salary * 0.062).round(2) -
	  (salary * 0.0145).round(2) -
	  edd_pit(salary) -
	  edd_ui(salary) -
	  edd_sdi(salary) -
	  edd_ett(salary)
      end

      # married dual income
      def self.fed_wh(salary)
	salary -= 4200.0
	[
	  TaxRate.new(0.0, 11_800.0, 0, 0.0),
	  TaxRate.new(11_800.0, 31_200.0, 0.0, 0.10),
	  TaxRate.new(31_200.0, 90_750.0, 1940.0, 0.12),
	  TaxRate.new(90_750.0, 180_200.0, 9086.0, 0.22),
	  TaxRate.new(180_200.0, 333_250.0, 28_765.0, 0.24),
	  TaxRate.new(333_250.0, 420_000.0, 65_497.0, 0.32),
	  TaxRate.new(420_000.0, 624_150.0, 93_257.0, 0.35),
	].each { |r|
	  if salary <= r.max
	    return (r.plus + (salary - r.min) * r.percent).round(2)
	  end
	}
	0.0
      end

      # married dual income
      def self.edd_pit(salary)
	salary -= 4401
	[
	  TaxRate.new(0.0, 8544.0, 0.0, 0.011),
	  TaxRate.new(8544.0, 20_255.0, 93.98, 0.022),
	  TaxRate.new(20_255.0, 31_969.0, 351.62, 0.044),
	  TaxRate.new(31_969.0, 44_377.0, 867.04, 0.066),
	  TaxRate.new(44_377.0, 56_085.0, 1685.97, 0.088),
	  TaxRate.new(56_085.0, 286_492.0, 2716.27, 0.1023),
	].each { |r|
	  if salary <= r.max
	    return (r.plus + (salary - r.min) * r.percent).round(2)
	  end
	}
	0.0
      end

      def self.edd_ui(salary)
	return 378.0 if 7000.0 <= salary
	salary * 0.054
      end

      def self.edd_sdi(salary)
	return 1229.09 if 122909.0 <= salary
	salary * 0.01
      end

      def self.edd_ett(salary)
	return 7.0 if 7000.0 <= salary
	salary * 0.001
      end

=begin
  - withholding
  - social security [6.2% of first $132900 for both corp and employee]
  - medicare [1.45% for both corp and employee] [additional 0.9% for that over 200K]
  - FUTA (is this really needed?)
 - FTB
  - SDI (State Disability Insurance) [1.0% of first $118371]
  - UI (Unemployment Insurance) [6.2% of first $7000]
  - ETT (Employment Training Tax) [0.1% of first $7000]
  - PIT (Personal Income Tax)
=end

    end
  end
end
