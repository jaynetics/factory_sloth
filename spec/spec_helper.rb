if RUBY_VERSION.start_with?('3.2')
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start
end

require 'factory_sloth'
require_relative 'factory_bot_stub'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    # This option will default to `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.before do
    FactorySloth::DoneTracker.reset
    FactorySloth.instance_variables.each { |iv| FactorySloth.remove_instance_variable(iv) }
  end
end

def fixture(name)
  File.read("#{__dir__}/fixtures/#{name}.rb")
end
