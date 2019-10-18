# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook

  class Invoice

    attr_accessor :id
    attr_accessor :submitted
    attr_accessor :amount
    attr_accessor :to
    attr_accessor :payments

    def initialize(h)
      @id = h['id']
      @submitted = h['submitted']
      @amount = h['amount']
      @to = h['to']
      @payments = h['payments']
    end

    def self.json_create(h)
      self.new(h)
    end

  end # Invoice
end # BalanceBook
