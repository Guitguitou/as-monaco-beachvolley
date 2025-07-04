class Session < ApplicationRecord
  belongs_to :user

  validates :title, :start_at, :end_at, :session_type, :user_id, presence: true

  enum :session_type, {
    entrainement: "entrainement",
    jeu_libre: "jeu_libre",
    tournoi: "tournoi",
    coaching_prive: "coaching_prive"
  }
end
