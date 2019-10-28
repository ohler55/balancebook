# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Contact

      attr_accessor :id
      attr_accessor :name
      attr_accessor :role
      attr_accessor :email
      attr_accessor :phone

      def initialize(id)
	@id = id
      end

      def validate(book)
	raise StandardError.new("Contact ID can not be empty.") unless !@id.nil? && 0 < @id.size
      end

    end
  end
end
