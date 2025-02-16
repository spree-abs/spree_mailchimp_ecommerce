# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "simplecov"
require "simplecov-console"
SimpleCov.formatter = SimpleCov::Formatter::Console
SimpleCov.start

require File.expand_path("dummy/config/environment.rb", __dir__)

require "rspec/rails"
require "ffaker"
require "webmock/rspec"
require "json_matchers/rspec"

JsonMatchers.schema_root = "spec/support/schemas"

WebMock.allow_net_connect!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

# Requires factories and other useful helpers defined in spree_core.
require "spree/testing_support/authorization_helpers"
require "spree/testing_support/controller_requests"
require "spree/testing_support/factories"
require "spree/testing_support/url_helpers"
require "spree/testing_support/order_walkthrough"
require "selenium-webdriver"

RSpec.configure do |config|
  # Infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::TestingSupport::UrlHelpers

  # == Requests support
  #
  # Adds convenient methods to request Spree's controllers
  # spree_get :index
  config.include Spree::TestingSupport::ControllerRequests, type: :controller

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.color = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Capybara javascript drivers require transactional fixtures set to false, and we use DatabaseCleaner
  # to cleanup after each test instead.  Without transactional fixtures set to false the records created
  # to setup a test will be unavailable to the browser, which runs under a separate server instance.
  config.use_transactional_fixtures = false

  config.fail_fast = ENV["FAIL_FAST"] || false
  config.order = "random"

  Rails.application.routes.default_url_options[:host] = "test.com"
end
