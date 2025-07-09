class Level < ApplicationRecord
  has_many :users
  has_many :session_levels
  has_many :sessions, through: :session_levels

  enum :gender, {
    male: "male",
    female: "female",
    mixed: "mixed"
  }
end
