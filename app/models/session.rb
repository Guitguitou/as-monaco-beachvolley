class Session < ApplicationRecord
  belongs_to :user
  has_many :session_levels, dependent: :destroy
  has_many :levels, through: :session_levels
  validates :title, :start_at, :end_at, :session_type, :user_id, presence: true

  enum :session_type, {
    entrainement: "entrainement",
    jeu_libre: "jeu_libre",
    tournoi: "tournoi",
    coaching_prive: "coaching_prive"
  }

  validate :end_at_after_start_at

  private

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    if end_at <= start_at
      errors.add(:end_at, "doit être après la date de début")
    end
  end
end
