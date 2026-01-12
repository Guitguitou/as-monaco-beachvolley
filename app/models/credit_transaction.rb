class CreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true

  enum :transaction_type, {
    purchase: 0,
    training_payment: 1,
    free_play_payment: 2,
    private_coaching_payment: 3,
    refund: 4,
    manual_adjustment: 5
  }

  validates :amount, presence: true
  after_create_commit :apply_amount_delta
  after_create_commit :check_low_credits_notification_after_create
  after_update_commit :apply_amount_update_delta
  after_update_commit :check_low_credits_notification_after_update
  after_destroy_commit :apply_amount_destroy_delta
  after_destroy_commit :check_low_credits_notification_after_destroy

  scope :payments, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment]]) }
  scope :refunds, -> { where(transaction_type: transaction_types[:refund]) }
  scope :revenue_transactions, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment], transaction_types[:refund]]) }
  scope :in_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  private

  def apply_amount_delta
    # Incremental update preserves any pre-existing balance baseline
    user.balance.update!(amount: (user.balance.amount || 0) + amount)
  end

  def apply_amount_update_delta
    previous = saved_change_to_amount? ? saved_change_to_amount.first : amount
    delta = amount - previous
    return if delta.zero?

    user.balance.update!(amount: (user.balance.amount || 0) + delta)
  end

  def apply_amount_destroy_delta
    user.balance.update!(amount: (user.balance.amount || 0) - amount)
  end

  def check_low_credits_notification_after_create
    # Règle 3: Notifier si les crédits passent sous 500
    # Le balance a déjà été mis à jour par apply_amount_delta
    # Le solde avant était donc current_balance - amount
    user.balance.reload
    current_balance = user.balance.amount
    previous_balance = current_balance - amount
    check_low_credits_notification(previous_balance, current_balance)
  end

  def check_low_credits_notification_after_update
    # Règle 3: Notifier si les crédits passent sous 500
    # Calculer le solde avant cette modification
    user.balance.reload
    current_balance = user.balance.amount
    old_amount = saved_change_to_amount? ? saved_change_to_amount.first : amount
    delta = amount - old_amount
    previous_balance = current_balance - delta
    check_low_credits_notification(previous_balance, current_balance)
  end

  def check_low_credits_notification_after_destroy
    # Règle 3: Notifier si les crédits passent sous 500
    # Le balance a déjà été mis à jour par apply_amount_destroy_delta
    # Le solde avant était donc current_balance + amount
    user.balance.reload
    current_balance = user.balance.amount
    previous_balance = current_balance + amount
    check_low_credits_notification(previous_balance, current_balance)
  end

  def check_low_credits_notification(previous_balance, current_balance)
    # Vérifier si on vient de passer sous 500 crédits (et qu'on était au-dessus avant)
    # Notifier seulement si on passe de >= 500 à < 500
    if previous_balance >= 500 && current_balance < 500 && current_balance >= 0
      # Vérifier qu'on n'a pas déjà envoyé une notification récemment (dans les dernières 24h)
      cache_key = "low_credits_notification:#{user.id}"
      last_notification = Rails.cache.read(cache_key)

      # Envoyer seulement si pas de notification dans les dernières 24h
      if last_notification.nil? || last_notification < 24.hours.ago
        SendPushNotificationJob.perform_later(
          user.id,
          title: "Crédits faibles",
          body: "Attention tu as moins de 500 crédits, pense à recharger 😉",
          url: Rails.application.routes.url_helpers.packs_path
        )
        # Mettre en cache pour 24h
        Rails.cache.write(cache_key, Time.current, expires_in: 24.hours)
      end
    end
  end

end
