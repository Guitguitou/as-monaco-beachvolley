# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    before_action :require_admin_or_financial_manager!

    TABS = %w[overview attendance revenue coaches alerts].freeze
    ANALYTICS = {
      "attendance" => Reporting::SeasonAttendance, "revenue" => Reporting::SeasonRevenue, "coaches" => Reporting::SeasonCoaching
    }.freeze

    def index
      @active_tab = TABS.include?(params[:tab]) ? params[:tab] : "overview"
      if ANALYTICS.key?(@active_tab)
        @season = SeasonSelectorComponent.season_from(params)
        @report = ANALYTICS.fetch(@active_tab).new(Reporting::SeasonMonths.new(@season))
      elsif @active_tab == "alerts"
        @alerts = Reporting::Alerts.new.all_alerts
      else
        @home = Admin::HomeDashboard.new(routes: self)
      end
    end
  end
end
