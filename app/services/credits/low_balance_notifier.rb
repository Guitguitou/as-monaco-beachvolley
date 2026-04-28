module Credits
  class LowBalanceNotifier
    THRESHOLD = 500

    def self.call(user:, previous_balance:, current_balance:)
      new(user: user, previous_balance: previous_balance, current_balance: current_balance).call
    end

    def initialize(user:, previous_balance:, current_balance:)
      @user = user
      @previous_balance = previous_balance
      @current_balance = current_balance
    end

    def call
      return unless crossed_threshold?

      cache_key = "low_credits_notification:#{user.id}"
      last_notification = Rails.cache.read(cache_key)
      return if last_notification.present? && last_notification >= 24.hours.ago

      SendPushNotificationJob.perform_later(
        user.id,
        title: "Crédits faibles",
        body: "Attention tu as moins de 500 crédits, pense à recharger 😉",
        url: Rails.application.routes.url_helpers.packs_path
      )
      Rails.cache.write(cache_key, Time.current, expires_in: 24.hours)
    end

    private

    attr_reader :user, :previous_balance, :current_balance

    def crossed_threshold?
      previous_balance >= THRESHOLD && current_balance < THRESHOLD && current_balance >= 0
    end
  end
end
