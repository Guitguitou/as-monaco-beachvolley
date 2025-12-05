class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:create, :destroy]

  def create
    authorize! :create, Registration

    target_user = determine_target_user
    requested_waitlist = ActiveModel::Type::Boolean.new.cast(params[:waitlist])

    result = RegistrationService.new(
      @session,
      target_user,
      can_bypass_deadline: can_bypass_deadline?,
      can_register_private_coaching: can_register_private_coaching?
    ).create(waitlist: requested_waitlist)

    if result[:success]
      redirect_to session_path(@session), notice: "Inscription réussie ✅"
    else
      redirect_to session_path(@session), alert: result[:errors].to_sentence
    end
  end

  def destroy
    authorize! :destroy, Registration

    target_user = determine_target_user_for_destroy

    result = RegistrationService.new(
      @session,
      target_user,
      can_manage_others_registrations: can_manage_others_registrations?,
      can_bypass_session_end: current_user.admin?
    ).destroy

    if result[:success]
      redirect_to session_path(params[:session_id]), notice: result[:notice]
    else
      redirect_to session_path(params[:session_id]), alert: result[:errors].to_sentence
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end

  def determine_target_user
    if params[:user_id].present? && (current_user.admin? || current_user == @session.user)
      User.find(params[:user_id])
    else
      current_user
    end
  end

  def determine_target_user_for_destroy
    if params[:user_id].present? && (current_user.admin? || current_user == @session.user)
      User.find(params[:user_id])
    else
      current_user
    end
  end

  def can_bypass_deadline?
    current_user.admin? || current_user == @session.user
  end

  def can_register_private_coaching?
    @session.coaching_prive? && (current_user.admin? || current_user == @session.user)
  end

  def can_manage_others_registrations?
    current_user.admin? || current_user == @session.user
  end
end
