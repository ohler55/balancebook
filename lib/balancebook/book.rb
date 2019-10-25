# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook

  class Book

    attr_accessor :company
    attr_accessor :fx
    attr_accessor :fx_url
    attr_accessor :fx_file
    attr_accessor :backups
    attr_accessor :data_file

    def initialize(data_file, fx_file, fx_url, backups)
      @data_file = File.expand_path(data_file)
      @company = Oj.load_file(@data_file)
      @fx_file = File.expand_path(fx_file)
      @fx_url = fx_url
      @fx = Oj.load_file(@fx_file)
      @backups = backups
    end

    def cmd(verb, type, args={})
      case verb
      when 'new'
	cmd_new(type, args)
      when 'show'
	cmd_show(type, args)
      when 'update'
	cmd_update(type, args)
      when 'del'
	cmd_del(type, args)
      when 'list'
	cmd_list(type, args)
      when 'report'
	cmd_report(type, args)
      else
	raise StandardError.new("#{verb} is not a valid command.")
      end
    end

    def cmd_new(type, args)
      case type
      when 'invoice'
	inv = Input::Invoice.new(self)
	@company.invoices << inv
	save_company()
	puts "\nInvoice #{inv.model.id} added.\n\n"
      else
	puts "*** new #{type} #{args}"
	# TBD
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
      end
    end

    def cmd_show(type, args)
      case type
      when 'fx'
	@fx.show(self, args)
      else
	puts "*** show #{type} #{args}"
	# TBD
	#  invoice
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
      end
    end

    def cmd_update(type, args)
      case type
      when 'fx'
	@fx.update(self, args)
	save_fx
      else
	puts "*** update #{type} #{args}"
	# TBD
	#  invoice
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
      end
    end

    def cmd_del(type, args)
      puts "*** del #{type} #{args}"
	# TBD
	#  invoice
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
    end

    def cmd_list(type, args)
      puts "*** list #{type} #{args}"
	# TBD
	#  invoice
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
    end

    def cmd_report(type, args)
	# TBD args are filters with a headers="foo,bar" cols="id,name"
      puts "*** report #{type} #{args}"
    end

    def save_fx
      rotate_files(@fx_file)
      Oj.to_file(@fx_file, @fx, indent: 2)
    end

    def save_company
      rotate_files(@data_file)
      Oj.to_file(@data_file, @company, indent: 2)
    end

    def rotate_files(f)
      return if @backups < 1
      @backups.step(1, -1) { |i|
	if 1 < i
	  old = "#{f}.#{i - 1}"
	else
	  old = f
	end
	nn = "#{f}.#{i}"
	File.rename(old, nn) if File.exist?(old)
      }
    end

  end
end
