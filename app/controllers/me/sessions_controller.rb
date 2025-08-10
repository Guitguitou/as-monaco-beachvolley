# frozen_string_literal: true

module Me
  class SessionsController < ApplicationController
    before_action :authenticate_user!

    def index
      mine = current_user.sessions_registered.includes(:levels, :user)
      @upcoming = mine.where("start_at >= ?", Time.current).order(:start_at)
      @past = mine.where("end_at < ?", Time.current).order(start_at: :desc)
    end

    def show
      @session = current_user.sessions_registered.find(params[:id])
    end
  end
end
