# frozen_string_literal: true

# Request spec helpers
RSpec.configure do |config|
  # Set default host for all request specs to avoid Host Authorization errors
  config.before(:each, type: :request) do
    host! 'test.host'
  end
end
