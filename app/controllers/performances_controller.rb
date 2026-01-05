# frozen_string_literal: true

class PerformancesController < ApplicationController
  before_action :authenticate_user!

  def index
    @stats = Stats::PerformanceDashboard.new.call
    @stats_by_group = Stats::PerformanceDashboard.new.by_group
  end
end

