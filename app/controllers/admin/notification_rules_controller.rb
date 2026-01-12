# frozen_string_literal: true

module Admin
  # Controller for managing notification rules in the admin panel
  class NotificationRulesController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_notification_rule, only: [:show, :edit, :update, :destroy]

    def index
      @notification_rules = NotificationRule.order(created_at: :desc)
    end

    def show
    end

    def new
      @notification_rule = NotificationRule.new
    end

    def create
      @notification_rule = NotificationRule.new(notification_rule_params)

      if @notification_rule.save
        redirect_to admin_notification_rules_path, notice: "Règle de notification créée avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @notification_rule.update(notification_rule_params)
        redirect_to admin_notification_rules_path, notice: "Règle de notification mise à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @notification_rule.destroy
      redirect_to admin_notification_rules_path, notice: "Règle de notification supprimée avec succès."
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user&.admin?
    end

    def set_notification_rule
      @notification_rule = NotificationRule.find(params[:id])
    end

    def notification_rule_params
      params.require(:notification_rule).permit(
        :name,
        :event_type,
        :title_template,
        :body_template,
        :enabled,
        conditions: {}
      )
    end
  end
end
