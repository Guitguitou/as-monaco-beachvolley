# frozen_string_literal: true

class SessionInvitationsController < ApplicationController
  before_action :authenticate_user!

  def create
    session = Session.find(params[:session_id])
    authorize! :read, session

    result = Sessions::Invitations.new(session: session, inviter: current_user)
      .invite(params[:invitee_ids], url: session_url(session))
    redirect_to session_path(session, Sessions::ReturnParams.from(params)), (result.success? ? :notice : :alert) => result.message
  end
end
