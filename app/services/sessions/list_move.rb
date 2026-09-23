# frozen_string_literal: true

module Sessions
  # Fait passer une inscription entre liste principale et liste d'attente, en
  # débitant ou remboursant le prix de la session dans la même transaction.
  # Un coaching privé est payé par le coach : les joueurs ne paient rien.
  class ListMove
    def initialize(session)
      @session = session
      @price = session.coaching_prive? ? 0 : session.price.to_i
    end

    def affordable?(registration)
      @price <= 0 || registration.user.balance.amount >= @price
    end

    def confirm(registration)
      move(registration, :confirmed) { |credits| credits.create_transaction }
    end

    def waitlist(registration)
      move(registration, :waitlisted) { |credits| credits.refund_transaction }
    end

    private

    def move(registration, status)
      ActiveRecord::Base.transaction do
        registration.update!(status: status)
        yield TransactionService.new(registration.user, @session, @price) if @price.positive?
      end
    end
  end
end
