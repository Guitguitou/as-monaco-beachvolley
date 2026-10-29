# frozen_string_literal: true

module Admin
  # Campagne affichée dans les onglets Commandes et Récap : celle demandée,
  # sinon la plus récente.
  class ShopCampaignChoice
    def initialize(campaign_id)
      @campaign_id = campaign_id
    end

    def campaign = @campaign ||= (@campaign_id.present? ? Shop::Campaign.find(@campaign_id) : Shop::Campaign.ordered.first)

    def options = Shop::Campaign.ordered.map { |campaign| [ campaign.name, campaign.id ] }
  end
end
