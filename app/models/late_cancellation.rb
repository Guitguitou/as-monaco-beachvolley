# frozen_string_literal: true

# LateCancellation model representing late cancellations of training sessions.
#
# Tracks users who cancelled after the cancellation deadline.
class LateCancellation < ApplicationRecord
  belongs_to :user
  belongs_to :session

  validates :user_id, presence: true
  validates :session_id, presence: true

  scope :for_trainings, -> { joins(:session).where(sessions: { session_type: 'entrainement' }) }
  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }
  scope :with_associations, -> { includes(:user, :session) }
end
