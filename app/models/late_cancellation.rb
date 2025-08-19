class LateCancellation < ApplicationRecord
  belongs_to :user
  belongs_to :session

  validates :user_id, presence: true
  validates :session_id, presence: true
end
