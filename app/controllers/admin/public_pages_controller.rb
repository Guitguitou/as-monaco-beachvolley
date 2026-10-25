# frozen_string_literal: true

module Admin
  # Pages publiques : une URL de web app Google Apps Script exposée sous
  # https://as-monaco-beachvolley.com/{slug}.
  class PublicPagesController < BaseController
    before_action :require_admin!
    before_action :set_public_page, only: [ :edit, :update, :destroy ]

    def index
      @public_pages = PublicPage.ordered
    end

    def new
      @public_page = PublicPage.new
    end

    def create
      @public_page = PublicPage.new(public_page_params)
      if @public_page.save
        redirect_to admin_public_pages_path, notice: "Page publique créée."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @public_page.update(public_page_params)
        redirect_to admin_public_pages_path, notice: "Page publique mise à jour."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @public_page.destroy!
      redirect_to admin_public_pages_path, notice: "Page publique supprimée."
    end

    private

    def set_public_page
      @public_page = PublicPage.find_by!(slug: params[:id])
    end

    def public_page_params
      params.require(:public_page).permit(:title, :slug, :script_url)
    end
  end
end
