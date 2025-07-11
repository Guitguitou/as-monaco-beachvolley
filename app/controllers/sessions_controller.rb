# frozen_string_literal: true

class SessionsController < ApplicationController
  def index
    @sessions = Session.includes(:user, :levels).order(start_at: :asc)
  end

  def show
    @session = Session.includes(:user, :levels).find(params[:id])
  end
end 
