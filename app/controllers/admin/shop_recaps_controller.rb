# frozen_string_literal: true

module Admin
  # Récap d'une campagne pour les marques, à consulter ou à télécharger en
  # Excel et en PDF (récap par marque et distribution par membre).
  class ShopRecapsController < BaseController
    before_action :require_admin!
    before_action :set_choice

    def show
      @recap = Shop::CampaignRecap.new(@choice.campaign) if @choice.campaign
    end

    def excel
      send_data Shop::RecapWorkbook.new(campaign).render, filename: filename("xlsx"), type: Shop::RecapWorkbook::MIME, disposition: "attachment"
    end

    def pdf
      send_data Shop::RecapPdf.new(campaign).render, filename: filename("pdf"), type: "application/pdf", disposition: "attachment"
    end

    private

    def set_choice
      @choice = ShopCampaignChoice.new(params[:campaign_id])
    end

    def campaign = @choice.campaign || raise(ActiveRecord::RecordNotFound)

    def filename(extension) = "recap-#{campaign.name.parameterize}.#{extension}"
  end
end
