# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Account
      extend Base

      def self.cmd(book, args, hargs)
	verb = args[0]
	verb = 'list' if verb.nil? || verb.include?('=')
	case verb
	when 'delete', 'del', 'rm'
	  delete(book, args, hargs)
	when 'list'
	  list(book)
	when 'new', 'create'
	  create(book, args[1..-1], hargs)
	when 'show'
	  show(book, args[1..-1], hargs)
	when 'transactions', 'transaction', 'trans'
	  Transactions.list(book, args[1..-1], hargs)
	when 'update'
	  update(book, args[1..-1], hargs)
	else
	  raise StandardError.new("Account can not #{verb}.")
	end
      end

      def self.cmd_choices
	['delete', 'list', 'new', 'show', 'transactions', 'update']
      end

      def self.create(book, args, hargs)
	# TBD
      end

      def self.delete(book, args, hargs)
	# TBD
      end

      def self.show(book, args, hargs)
	c = book.company
	id = extract_arg(:id, "ID", args, hargs, c.accounts.map { |a| a.id } + c.accounts.map { |a| a.name })

	acct = c.find_account(id)
	raise StandardError.new("Failed to find account #{id}.") if acct.nil?
	puts "\n#{UNDERLINE}#{acct.name}#{' '*(80 - acct.name.size)}#{NORMAL}"
	puts "ID:                #{acct.id}"
	puts "Kind:              #{acct.kind}"
	puts "Address:           #{acct.address}" unless acct.address.nil?
	puts "ABA:               #{acct.aba}" unless acct.aba.nil?
	puts "Number:            #{book.acct_info[acct.id]['number']}" unless book.acct_info[acct.id].nil?
	puts "Transaction Count: #{acct.transactions.size}"
	puts "Currency:          #{acct._currency.id}"
	puts "Balance:           #{acct.balance.round(2)}"
	puts
      end

      def self.list(book)
	table = Table.new('Accounts', [
			  Col.new('ID', -1, :id, nil),
			  Col.new('Name', -1, :name, nil),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new('Cur', -3, :currency, nil),
			  Col.new('ABA', -10, :aba, nil),
			  Col.new('Kind', -8, :kind, nil),
			  Col.new('address', -1, :address, nil),
			  ])

	table.rows = book.company.accounts
	table.display
      end

      def self.update(book, args, hargs)
	c = book.company
	period = extract_period(book, hargs)
	id = extract_arg(:id, "ID", args, hargs, c.accounts.map { |a| a.id } + c.accounts.map { |a| a.name })
	file = extract_arg(:file, "File", args[1..-1], hargs)

	acct = book.company.find_account(id)
	raise StandardError.new("Failed to find account #{id}.") if acct.nil?

	content = File.read(File.expand_path(file))
	ofx = OFX.parse(content)

	bank = ofx['OFX']['BANKMSGSRSV1']['STMTTRNRS']
	raise StandardError.new("OFX file indicated a non-OK status.") unless 0 == bank['STATUS']['CODE'].to_i
	unless bank['STMTRS']['BANKACCTFROM']['ACCTID'] == book.acct_info[acct.id]['number']
	  raise StandardError.new("OFX file account number mismatch.")
	end

	bank['STMTRS']['BANKTRANLIST']['STMTTRN'].each { |bt|
	  amount = bt['TRNAMT'].to_f
	  t = bt['DTPOSTED']
	  date = "#{t[0..3]}-#{t[4..5]}-#{t[6..7]}"
	  trans = Model::Transaction.new(bt['FITID'], date, amount, bt['NAME'].strip)
	  if acct.add_trans(trans)
	    puts "#{trans.id} added"
	    c.dirty
	  end
	}
      end

    end
  end
end
