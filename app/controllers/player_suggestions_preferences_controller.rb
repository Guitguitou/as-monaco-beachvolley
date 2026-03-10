# frozen_string_literal: true

class PlayerSuggestionsPreferencesController < ApplicationController
  before_action :authenticate_user!

  def update
    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
    current_user.update!(player_suggestions_push_enabled: enabled)

    notice = enabled ? "Notifications de suggestions activees." : "Notifications de suggestions desactivees."
    redirect_to player_listings_path, notice: notice
  end
end
