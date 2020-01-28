# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Cmd
    BOLD = "\x1b[1m"
    NORMAL = "\x1b[m"
    UNDERLINE = "\x1b[4m"
  end
end

require 'balancebook/cmd/period'
require 'balancebook/cmd/base'
require 'balancebook/cmd/help'
require 'balancebook/cmd/table'
require 'balancebook/cmd/account'
require 'balancebook/cmd/bill'
require 'balancebook/cmd/balance'
require 'balancebook/cmd/datediff'
require 'balancebook/cmd/payroll'
require 'balancebook/cmd/links'
require 'balancebook/cmd/receipts'
require 'balancebook/cmd/category'
require 'balancebook/cmd/corporation'
require 'balancebook/cmd/fx'
require 'balancebook/cmd/invoice'
require 'balancebook/cmd/ledger'
require 'balancebook/cmd/ofx'
require 'balancebook/cmd/report'
require 'balancebook/cmd/tax'
require 'balancebook/cmd/transactions'
require 'balancebook/cmd/transfer'
