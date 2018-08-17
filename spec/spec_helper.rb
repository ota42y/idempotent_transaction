require 'bundler/setup'
require 'idempotent_transaction'
require 'active_record'
require 'database_rewinder'

# require_relative '../lib/idempotent_transaction'

RSpec.configure do |config|
  ActiveRecord::Base.configurations = { 'test' => { 'adapter' => 'sqlite3', 'database' => ':memory:' } }
  ActiveRecord::Base.establish_connection :test

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseRewinder.clean_all
  end

  config.after do
    DatabaseRewinder.clean
  end
end
