# frozen_string_literal: true

# FactoryBot configuration
# This file ensures FactoryBot methods are available in all specs
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
