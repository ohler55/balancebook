# Copyright (c) 2019, Peter Ohler, All rights reserved.

require 'date'

require 'ox'

module BalanceBook
  module Cmd

    class Account
      extend Base

      def self.update(book, args={})
	first, last = extract_date_range(book, args)
	file = args[:file]
	name = args[:id]
	acct = book.company.find_account(name)
	raise StandardError.new("Failed to find account #{name}.") if acct.nil?

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
	  acct.add_trans(trans)
	}
	acct.sort_trans
	"Account #{acct.id}"
      end

      def self.show(book, args={})
	name = args[:id]
	acct = book.company.find_account(name)
	raise StandardError.new("Failed to find account #{name}.") if acct.nil?
	puts "\n#{acct.name} #{acct.kind.downcase}"
	puts "ID: #{acct.id}"
	puts "Name: #{acct.name}"
	puts "Address: #{acct.address}"
	puts "ABA: #{acct.aba}"
	puts "Number: #{book.acct_info[acct.id]['number']}"
	puts
      end

      def self.list(book, args={})
	table = Table.new('Accounts', [
			  Col.new('ID', -10, :id, nil),
			  Col.new('Name', -20, :name, nil),
			  Col.new('Balance', 10, :balance, '%.2f'),
			  Col.new('Cur', -3, :currency, nil),
			  Col.new('ABA', -10, :aba, nil),
			  Col.new('Kind', -8, :kind, nil),
			  Col.new('address', -50, :address, nil),
			  ])

	table.rows = book.company.accounts
	table.display
      end

    end
  end
end
