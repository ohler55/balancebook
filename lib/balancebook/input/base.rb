# Copyright (c) 2019, Peter Ohler, All rights reserved.

module BalanceBook
  module Input

    class Base

      def read_str(label)
	print("#{label}: ")
	STDIN.readline.strip
      end

      def read_date(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	if 0 < v.size
	  unless /^(19|20)\d\d[-.](0[1-9]|1[012])[-.](0[1-9]|[12][0-9]|3[01])$/.match?(date.to_s)
	    raise StandardError.new("#{where} of #{date} did not match format YYY-MM-DD.")
	  end
	else
	  v = Date.today.to_s
	end
	v
      end

      def read_amount(label)
	print("#{label}: ")
	v = STDIN.readline.strip
	v.to_f
      end

    end
  end
end
