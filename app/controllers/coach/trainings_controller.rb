# frozen_string_literal: true

module Coach
  class TrainingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_coach_or_admin!

    def index
      # Show trainings grouped by level with latest notes first
      trainings = Session.includes(:levels)
                         .where(session_type: 'entrainement')
                         .where.not(coach_notes: [nil, ''])
                         .order(start_at: :desc)

      # Optional filter: only sessions coached by me
      if params[:only_mine].present?
        trainings = trainings.where(user_id: current_user.id)
      end

      # Group by level id (sessions may have multiple levels; duplicate in multiple groups)
      @by_level_id = Hash.new { |h, k| h[k] = [] }
      trainings.each do |s|
        if s.levels.any?
          s.levels.each { |lvl| @by_level_id[lvl.id] << s }
        else
          @by_level_id[nil] << s
        end
      end

      @levels = Level.where(id: @by_level_id.keys.compact).index_by(&:id)
    end

    private

    def ensure_coach_or_admin!
      redirect_to root_path, alert: "Accès réservé aux coachs/admins" unless current_user.admin? || current_user.coach?
    end
  end
end
