# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'pry'
require "verse/core"
require "bundler"

Bundler.require

Dir[File.join(__dir__, "helpers", "*.rb")].each{ |file| require file }

ENV["APP_ENVIRONMENT"] ||= "test"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # config.include Rack::Test::Methods
  # config.include VerseTarget, :verse
  # config.include AuthHelper
  # config.include FixturesHelper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
