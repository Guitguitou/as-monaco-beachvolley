# frozen_string_literal: true

class PerformancesController < ApplicationController
  before_action :authenticate_user!

  def index
    @stats = Stats::PerformanceDashboard.new.call
  end
end

