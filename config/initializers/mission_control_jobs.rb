# frozen_string_literal: true

# Mission Control Jobs is mounted behind our own Devise admin-only auth
# (see config/routes.rb), so its default HTTP Basic auth is disabled.
Rails.application.configure do
  config.mission_control.jobs.base_controller_class = "ApplicationController"
  config.mission_control.jobs.http_basic_auth_enabled = false
end
