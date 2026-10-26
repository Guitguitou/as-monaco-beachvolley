# frozen_string_literal: true

# Affiche une page publique (web app Google Apps Script) en plein écran,
# accessible connecté ou non.
class PublicPagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :redirect_non_activated_users

  def show
    @public_page = PublicPage.find_by!(slug: params[:slug])
    render layout: false
  end
end
