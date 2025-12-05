# frozen_string_literal: true

# Capybara configuration for system tests
RSpec.configure do |config|
  # Run JS-enabled browser for system tests
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end

# Increase Capybara wait time for JS to settle
Capybara.default_max_wait_time = 5
Capybara.app_host = 'http://test.host'
Capybara.server_host = 'test.host'

