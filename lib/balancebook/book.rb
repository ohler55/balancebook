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
      Oj.default_options = { ignore_under: true, omit_nil: true }
    end

    def validate
      @company.validate(self)
      @fx.validate(self)
    end

    def help
      puts 'Commands:'
      [
	Cmd::Help.new('account', ['acct'], 'Account commands', nil),
	Cmd::Help.new('bill', nil, 'Bill commands', nil),
	Cmd::Help.new('category', ['cat'], 'Category commands', nil),
	Cmd::Help.new('company', nil, 'Company commands', nil),
	Cmd::Help.new('contact', nil, 'Contact commands', nil),
	Cmd::Help.new('corporation', nil, 'Corporation commands', nil),
	Cmd::Help.new('date-diff', ['date-diffs'], 'Date difference report', nil),
	Cmd::Help.new('fx', nil, 'FX commands', nil),
	Cmd::Help.new('invoice', nil, 'Invoice commands', nil),
	Cmd::Help.new('ledger', ['entry'], 'Ledger commands', nil),
	Cmd::Help.new('link', nil, 'Link commands linking ledger entries and account transactions', nil),
	Cmd::Help.new('receipt', ['receipts'], 'Receipt commands', nil),
	Cmd::Help.new('report', ['reports'], 'Report commands to display or generate CSV reports', nil),
	Cmd::Help.new('tax', ['taxes'], 'Tax commands', nil),
	Cmd::Help.new('transaction', ['trans', 'tx'], 'Account transaction commands (same as account transaction)', nil),
	Cmd::Help.new('transfer', ['xfer'], 'Transfer commands to manage transfers between accounts', nil),
      ].each { |h| h.show(false) }
    end

    def act(args=[])
      hargs = {}
      args[1..].each { |a|
	k, v = a.split('=')
	hargs[k.to_sym] = v
      }
      case args[0]
      when 'help', '?'
	help
      when 'account', 'acct', 'bank'
	Cmd::Account.cmd(self, args[1..-1], hargs)
      when 'bill'
	Cmd::Bill.cmd(self, args[1..-1], hargs)
      when 'category', 'cat'
	Cmd::Category.cmd(self, args[1..-1], hargs)
      when 'corporation', 'corp'
	Cmd::Corporation.cmd(self, args[1..-1], hargs)
      when 'date-diffs', 'date-diff'
	Cmd::DateDiff.cmd(self, args[1..-1], hargs)
      when 'fx'
	Cmd::Fx.cmd(self, args[1..-1], hargs)
      when 'invoice'
	Cmd::Invoice.cmd(self, args[1..-1], hargs)
      when 'ledger', 'entry'
	Cmd::Ledger.cmd(self, args[1..-1], hargs)
      when 'link', 'links'
	Cmd::Links.cmd(self, args[1..-1], hargs)
      when 'payroll'
	Cmd::Payroll.cmd(self, args[1..-1], hargs)
      when 'receipt', 'receipts'
	Cmd::Receipts.cmd(self, args[1..-1], hargs)
      when 'reports', 'report'
	Cmd::Report.cmd(self, args[1..-1], hargs)
      when 'tax', 'taxes'
	Cmd::Tax.cmd(self, args[1..-1], hargs)
      when 'transaction', 'tx', 'trans'
	Cmd::Transactions.cmd(self, args[1..-1], hargs)
      when 'transfer', 'xfer'
	Cmd::Transfer.cmd(self, args[1..-1], hargs)
      else
	return false
      end
      save_company() if @save_ok && @company._dirty
      save_fx() if @save_ok && @fx._dirty
      true
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
