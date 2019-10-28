# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Tax

      attr_accessor :id
      attr_accessor :name
      attr_accessor :percent

      def initialize(id, name, percent)
	@id = id
	@name = name
	@percent = percent
      end

      def validate(book)
	raise StandardError.new("Tax ID can not be empty.") unless !@id.nil? && 0 < @id.size
	raise StandardError.new("Tax percent #{@percent} must be between 0.0 and 100%.") unless 0.0 < @percent && @percent < 100.0
      end

    end
  end
end
