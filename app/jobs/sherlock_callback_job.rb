# frozen_string_literal: true

class SherlockCallbackJob < ApplicationJob
  queue_as :default

  def perform(callback_params)
    Sherlock::HandleCallback.new(callback_params).call
  end
end
