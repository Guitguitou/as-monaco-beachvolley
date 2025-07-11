class Level < ApplicationRecord
  has_many :users
  has_many :session_levels
  has_many :sessions, through: :session_levels

  enum :gender, {
    male: "male",
    female: "female",
    mixed: "mixed"
  }

  def display_name
    case gender
    when "male"
      name + " M"
    when "female"
      name + " F"
    when "mixed"
      name + " X"
    else
      name
    end
  end
end
