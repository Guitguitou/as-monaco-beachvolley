module Sessions
  # Rembourse et retire les inscriptions d'une session qui n'aura pas lieu
  # (et le coach d'un coaching privé, qui l'avait payé). Renvoie les joueurs
  # confirmés, à prévenir.
  class RegistrationsRefund
    def initialize(session)
      @session = session
    end

    def call
      confirmed_users = @session.registrations.confirmed.includes(:user).map(&:user)
      @session.registrations.includes(:user).find_each do |registration|
        refund(registration.user, registration.required_credits_for(registration.user))
        registration.destroy!
      end
      refund(@session.user, @session.price) if @session.coaching_prive?
      confirmed_users
    end

    private

    def refund(user, amount)
      TransactionService.new(user, @session, amount).refund_transaction if amount.positive?
    end
  end
end
