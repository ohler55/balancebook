#!/usr/bin/env ruby

home = File.expand_path(".")

require File.join(home, "lib/balancebook/version")

puts "Releasing BalanceBook gem version #{BalanceBook::VERSION}"

tags = `git tag`.split("\n")
tag = "v#{BalanceBook::VERSION}"
unless tags.include?(tag)
  puts "tagging release with #{tag}"
  `git tag -m "release #{BalanceBook::VERSION}" v#{BalanceBook::VERSION}`
  `git push --tags`
end

puts "building gem"
out = `gem build balancebook.gemspec`
exit(0) unless out.include?("Success")

puts "pushing balancebook-#{BalanceBook::VERSION}.gem"
out = `gem push balancebook-#{BalanceBook::VERSION}.gem`
puts out
