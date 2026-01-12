# frozen_string_literal: true

# Model for defining notification rules that can be created by admins
# or defined in code. Each rule defines when and how to send notifications.
class NotificationRule < ApplicationRecord
  # Event types that can trigger notifications
  EVENT_TYPES = %w[
    session_created
    session_cancelled
    registration_opened
    registration_confirmed
    registration_cancelled
    credit_low
    stage_created
    stage_registration_opened
  ].freeze

  validates :name, presence: true
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :title_template, presence: true
  validates :body_template, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :for_event, ->(event_type) { where(event_type: event_type) }

  # Check if this rule should trigger for the given context
  def matches?(context)
    return false unless enabled?

    # If no conditions, always match
    return true if conditions.blank?

    # Check each condition
    conditions.all? do |key, value|
      context_value = context[key.to_sym] || context[key.to_s]
      case value
      when Hash
        # Support operators like { gt: 5 }, { in: [1, 2, 3] }
        check_condition(context_value, value)
      else
        context_value == value
      end
    end
  end

  # Render the title with the given context
  def render_title(context)
    render_template(title_template, context)
  end

  # Render the body with the given context
  def render_body(context)
    render_template(body_template, context)
  end

  private

  def check_condition(value, condition_hash)
    condition_hash.all? do |operator, expected|
      case operator.to_s
      when "gt"
        value.to_f > expected.to_f
      when "gte"
        value.to_f >= expected.to_f
      when "lt"
        value.to_f < expected.to_f
      when "lte"
        value.to_f <= expected.to_f
      when "in"
        Array(expected).include?(value)
      when "not_in"
        !Array(expected).include?(value)
      else
        value == expected
      end
    end
  end

  def render_template(template, context)
    template.gsub(/\{\{(\w+)\}\}/) do |_match|
      key = Regexp.last_match(1)
      context[key.to_sym] || context[key.to_s] || ""
    end
  end
end
