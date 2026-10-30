# frozen_string_literal: true

module Admin
  # Campagnes de commande groupée (cf. GLOSSARY.md) : dates, statut et
  # message affiché en tête de la boutique.
  class ShopCampaignsController < BaseController
    before_action :require_admin!
    before_action :set_campaign, only: [ :edit, :update ]

    def index
      @campaigns = Shop::Campaign.ordered
    end

    def new
      @campaign = Shop::Campaign.new(opens_on: Date.current, closes_on: Date.current + 14)
    end

    def create
      @campaign = Shop::Campaign.new(campaign_params)
      redirect_or_render(@campaign.save, :new, to: admin_shop_campaigns_path, notice: "Campagne créée")
    end

    def edit; end

    def update
      redirect_or_render(@campaign.update(campaign_params), :edit, to: admin_shop_campaigns_path, notice: "Campagne mise à jour")
    end

    private

    def set_campaign
      @campaign = Shop::Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:shop_campaign).permit(:name, :opens_on, :closes_on, :status, :welcome_message, :allow_edits)
    end
  end
end
