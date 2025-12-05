# frozen_string_literal: true

# Devise and Warden configuration for tests
RSpec.configure do |config|
  # Configure Devise for controller specs
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Devise helpers for request specs (sign_in, sign_out)
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :request
  config.include Warden::Test::Helpers, type: :system

  # Setup Devise mapping for controller specs
  config.before(:each, type: :controller) do
    @request.env["devise.mapping"] = Devise.mappings[:user] if @request
  end

  # Clean up Warden after each request/system spec
  config.after(type: :request) do
    Warden.test_reset!
  end

  config.after(type: :system) do
    Warden.test_reset!
  end
end

