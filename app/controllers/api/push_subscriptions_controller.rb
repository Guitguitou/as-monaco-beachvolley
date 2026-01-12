# frozen_string_literal: true

module Api
  # Controller for managing push notification subscriptions
  class PushSubscriptionsController < ApplicationController
    before_action :authenticate_user!

    # POST /api/push_subscriptions
    # Creates or updates a push subscription for the current user
    def create
      subscription = current_user.push_subscriptions.find_or_initialize_by(
        endpoint: subscription_params[:endpoint]
      )

      if subscription.update(subscription_params)
        render json: { status: "success", message: "Subscription saved" }, status: :created
      else
        render json: { status: "error", errors: subscription.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/push_subscriptions
    # Removes a push subscription by endpoint
    def destroy
      subscription = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
      
      if subscription
        subscription.destroy
        render json: { status: "success", message: "Subscription removed" }
      else
        render json: { status: "error", message: "Subscription not found" }, status: :not_found
      end
    end

    private

    def subscription_params
      params.require(:push_subscription).permit(:endpoint, :p256dh, :auth)
    end
  end
end
