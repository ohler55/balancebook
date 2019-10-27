# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Account

      attr_accessor :id
      attr_accessor :name
      attr_accessor :address
      attr_accessor :id
      attr_accessor :aba
      attr_accessor :kind

      def initialize(id)
	@id = id
      end

    end
  end
end
