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
    attr_accessor :verbose

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

      @fx.prepare(self)
      @company.prepare(self)
    end

    def validate
      @company.validate(self)
      @fx.validate(self)
    end

    def cmd(verb, type, args={})
      case verb
      when 'new', 'create'
	cmd_new(type, args)
      when 'show'
	cmd_show(type, args)
      when 'update'
	cmd_update(type, args)
      when 'delete', 'del'
	cmd_del(type, args)
      when 'list'
	cmd_list(type, args)
      when 'import'
	cmd_import(type, args)
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
	@company.add_invoice(self, obj) unless obj.nil?
      when 'category', 'cat'
	obj = Cmd::Category.create(self, args)
	@company.add_category(self, obj) unless obj.nil?
      when 'tax'
	obj = Cmd::Tax.create(self, args)
	@company.add_tax(self, obj) unless obj.nil?
      when 'entry', 'ledger'
	obj = Cmd::Ledger.create(self, args)
	@company.add_entry(self, obj) unless obj.nil?
      when 'transaction', 'trans', 'bank'
	obj = Cmd::Transactions.create(self, args)
      else
	puts "*** new #{type} #{args}"
	# TBD
	#  account
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
      when 'account'
	Cmd::Account.show(self, args)
      when 'invoice'
	Cmd::Invoice.show(self, args)
      when 'entry', 'ledger'
	Cmd::Ledger.show(self, args)
      when 'Customer', 'cust'
	Cmd::Customer.show(self, args)
      else
	raise StandardError.new("#{type} is not a valid type for a show command.")
      end
    end

    def cmd_update(type, args)
      updated = nil
      case type
      when 'fx'
	Cmd::Fx.update(self, args)
	save_fx if @save_ok
      when 'account'
	updated = Cmd::Account.update(self, args)
      when 'links'
	updated = Cmd::Links.update(self, args)
      when 'receipt'
	updated = Cmd::Receipts.update(self, args)
      else
	puts "*** update #{type} #{args}"
	# TBD
	#  invoice
	#  entry
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
      updated = nil
      case type
      when 'category', 'cat'
	updated = Cmd::Category.delete(self, args)
      when 'tax'
	updated = Cmd::Tax.delete(self, args)
      else
	puts "*** del #{type} #{args}"
	# TBD
	#  invoice
	#  account - only if not referenced by anything
	#  enrtry
	#  customer
      end
      if updated
	if @save_ok
	  save_company()
	  puts "\n#{@company.name} saved.\n\n"
	else
	  puts "\n#{@company.name} NOT saved.\n\n"
	end
      end
    end

    def cmd_list(type, args)
      case type
      when 'fx', 'rate', 'rates'
	Cmd::Fx.show(self, args)
      when 'invoice', 'invoices'
	Cmd::Invoice.list(self, args)
      when 'account', 'accounts'
	Cmd::Account.list(self, args)
      when 'transaction', 'transactions', 'trans', 'bank'
	Cmd::Transactions.list(self, args)
      when 'ledger'
	Cmd::Ledger.list(self, args)
      when 'category', 'categories', 'cat'
	Cmd::Category.list(self, args)
      when 'tax', 'taxes'
	Cmd::Tax.list(self, args)
      when 'customer', 'customers', 'cust'
	Cmd::Customer.list(self, args)
      when 'transfer', 'xfer'
	Cmd::Transfer.list(self, args)
      when 'receipts'
	Cmd::Receipts.report(self, args)
      else
	raise StandardError.new("#{type} is not a valid type for a list command.")
      end
    end

    def cmd_import(type, args)
      case type
      when 'entry', 'ledger'
	changed = Cmd::Ledger.import(self, args)
      else
	raise StandardError.new("#{type} is not a valid type for a show command.")
      end
      if changed
	if @save_ok
	  save_company()
	  puts "\n#{@company.name} saved.\n\n"
	else
	  puts "\n#{@company.name} NOT saved.\n\n"
	end
      end
    end

    def cmd_report(type, args)
      case type
      when 'balance'
	Cmd::Balance.report(self, args)
      when 'links'
	Cmd::Links.report(self, args)
      when 'receipts'
	Cmd::Receipts.report(self, args)
      end
=begin
      rep = @reports.send(type, args)
      csv = args[:csv]
      if csv.nil?
	rep.display
      else
	File.open(csv, 'w') { |f|
	  rep.csv(f)
	}
      end
=end
    end

    def save_fx
      rotate_files(@fx_file)
      Oj.to_file(@fx_file, @fx, mode: :object, indent: 2, ignore_under: true, omit_nil: true)
    end

    def save_company
      rotate_files(@data_file)
      Oj.to_file(@data_file, @company, mode: :object, indent: 2, ignore_under: true, omit_nil: true)
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
