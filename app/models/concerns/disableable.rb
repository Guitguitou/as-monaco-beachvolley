# frozen_string_literal: true

# Provides soft-delete functionality for models via a disabled_at timestamp.
# When a record is disabled, it can be prevented from certain actions (e.g., login for users).
#
# Usage:
#   class User < ApplicationRecord
#     include Disableable
#   end
#
#   user.disable!
#   user.disabled? # => true
#   user.enable!
#   user.disabled? # => false
#
module Disableable
  extend ActiveSupport::Concern

  included do
    scope :enabled, -> { where(disabled_at: nil) }
    scope :disabled, -> { where.not(disabled_at: nil) }
  end

  def disabled?
    disabled_at.present?
  end

  def disable!
    update!(disabled_at: Time.current) unless disabled?
  end

  def enable!
    update!(disabled_at: nil) if disabled?
  end
end
