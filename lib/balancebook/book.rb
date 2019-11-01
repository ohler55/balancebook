# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook

  class Book

    attr_accessor :company
    attr_accessor :fx
    attr_accessor :fx_url
    attr_accessor :fx_file
    attr_accessor :backups
    attr_accessor :data_file
    attr_accessor :save_ok
    attr_accessor :reports
    attr_accessor :acct_info

    def initialize(data_file, fx_file, fx_url, backups, save_ok, acct_info)
      @data_file = File.expand_path(data_file)
      @company = Oj.load_file(@data_file)
      @acct_info = acct_info
      @fx_file = File.expand_path(fx_file)
      @fx_url = fx_url
      @fx = Oj.load_file(@fx_file)
      @backups = backups
      @save_ok = save_ok
      @reports = Report::Reports.new(self)
    end

    def validate
      @company.validate(self)
      @fx.validate(self)
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
      obj = nil
      case type
      when 'invoice'
	obj = Cmd::Invoice.create(self, args)
	@company.add_invoice(self, obj)
      else
	puts "*** new #{type} #{args}"
	# TBD
	#  account
	#  transaction
	#  category
	#  tax
	#  customer
      end
      unless obj.nil?
	if @save_ok
	  save_company()
	else
	  puts Oj.dump(obj, indent: 2)
	end
	puts "\n#{obj.class.to_s.split('::')[-1]} #{obj.id} added.\n\n"
      end
    end

    def cmd_show(type, args)
      case type
      when 'fx'
	Cmd::Fx.show(self, args)
	#@fx.show(self, args)
      when 'account'
	Cmd::Account.show(self, args)
      else
	puts "*** show #{type} #{args}"
	# TBD
	#  invoice
	#  transaction
	#  category
	#  tax
	#  customer
      end
    end

    def cmd_update(type, args)
      updated = nil
      case type
      when 'fx'
	# TBD change to cmd?
	@fx.update(self, args)
	save_fx
      when 'account'
	updated = Cmd::Account.update(self, args)
      else
	puts "*** update #{type} #{args}"
	# TBD
	#  invoice
	#  transaction
	#  category
	#  tax
	#  customer
      end
      if updated
	if @save_ok
	  save_company()
	end
	puts "\n#{updated} updated.\n\n"
      end
    end

    def cmd_del(type, args)
      puts "*** del #{type} #{args}"
	# TBD
	#  invoice
	#  account - only if not referenced by anything
	#  transaction
	#  category
	#  tax
	#  customer
    end

    def cmd_list(type, args)
      case type
      when 'fx', 'rate', 'rates'
	Cmd::Fx.show(self, args)
      when 'invoice', 'invoices'
	Cmd::Invoice.list(self, args)
      when 'account', 'accounts'
	Cmd::Account.list(self, args)
      when 'transaction', 'transactions', 'ledger'
	# TBD
      when 'category', 'categories'
	# TBD
      when 'tax', 'taxes'
	# TBD
      when 'customer', 'customers'
	# TBD
      else
	raise StandardError.new("#{type} is not a valid type for a list command.")
      end
    end

    def cmd_report(type, args)
      rep = @reports.send(type, args)
      csv = args[:csv]
      if csv.nil?
	rep.display
      else
	File.open(csv, 'w') { |f|
	  rep.csv(f)
	}
      end
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
