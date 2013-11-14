gem 'pry'
require 'pry'

gem 'simplecov'
require 'simplecov'
SimpleCov.start do
  add_filter "spec/"
end

RSpec.configure do |config|
  # ## Mock Framework
  config.mock_with :rspec
  config.order = "random"
end
