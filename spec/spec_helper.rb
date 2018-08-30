require "simplecov"
require "codecov"
SimpleCov.formatter = SimpleCov::Formatter::Codecov
SimpleCov.start { add_filter "/spec/" }

require "shopify-lita-slack"
require "lita/rspec"

require "pry"

Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

Lita.configure do |config|
  config.redis[:host] = ENV["REDIS_HOST"]
  config.redis[:port] = ENV["REDIS_PORT"]
end