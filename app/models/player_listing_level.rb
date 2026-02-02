class PlayerListingLevel < ApplicationRecord
  belongs_to :player_listing
  belongs_to :level

  validates :level_id, uniqueness: { scope: :player_listing_id }
end
