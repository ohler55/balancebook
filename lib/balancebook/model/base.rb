# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Model

    class Base

      def validate_date(where, date)
	unless /^(19|20)\d\d[-.](0[1-9]|1[012])[-.](0[1-9]|[12][0-9]|3[01])$/.match?(date.to_s)
	  raise StandardError.new("#{where} of #{date} did not match format YYY-MM-DD.")
	end
      end

    end
  end
end
