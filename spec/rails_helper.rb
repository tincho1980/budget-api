# RSpec is used only for the request specs that document the API with rswag
# (spec/requests). The rest of the suite stays in Minitest (test/).
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Same fixtures and sample files as the Minitest suite.
  config.fixture_paths = [ Rails.root.join("test/fixtures") ]
  config.file_fixture_path = Rails.root.join("test/fixtures/files")
  config.global_fixtures = :all
  config.use_transactional_fixtures = true

  config.include ActiveJob::TestHelper
  config.filter_rails_from_backtrace!
  config.disable_monkey_patching!
  config.order = :random
end
