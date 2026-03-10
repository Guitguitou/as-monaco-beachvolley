# frozen_string_literal: true

class PlayerSuggestionNotification < ApplicationRecord
  belongs_to :user

  validates :event_type, :fingerprint, presence: true
end
