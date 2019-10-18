# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook

  class Book

    attr_accessor :companies
    attr_accessor :exchange

    def initialize(h)
      @companies = h['companies']
      @exchange = h['exchange']
    end

    def self.json_create(h)
      self.new(h)
    end

  end # Book
end # BalanceBook
