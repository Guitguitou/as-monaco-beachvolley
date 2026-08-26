class SessionLevel < ApplicationRecord
  belongs_to :session
  belongs_to :level

  # priority: rang de priorité du groupe pour la session (0 = plus prioritaire)
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered_by_priority, -> { order(:priority, :id) }
end
