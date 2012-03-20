require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
if ENV["COVERAGE"]
  SimpleCov.start
end

