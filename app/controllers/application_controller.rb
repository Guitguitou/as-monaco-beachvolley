# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  before_action :authenticate_user!, except: :accueil
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_non_activated_users

  def accueil
    # Redirect authenticated non-activated users to packs
    if user_signed_in? && !current_user.activated? && !current_user.admin? && !current_user.financial_manager?
      redirect_to packs_path
      return
    end

    render layout: "home"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  private

  def redirect_non_activated_users
    return unless user_signed_in?

    service = NonActivatedUserRedirectService.new(current_user, request.path)
    return unless service.should_redirect?

    redirect_to packs_path, alert: service.redirect_message
  end
end
