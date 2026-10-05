# frozen_string_literal: true

module Reporting
  # Sessions faites et montant payé en crédits, par joueur et par type de
  # session, sur une période. Une session compte si elle a eu lieu dans la
  # période et que le joueur l'a payée, remboursements déduits.
  #
  #   Reporting::PlayerSessionSpending.new(range).rows
  #   # => [ #<Row user: …, by_type: { "entrainement" => #<Stat count: 3, amount: 24.0> } >, … ]
  class PlayerSessionSpending
    Stat = Data.define(:count, :amount) do
      def self.empty = new(count: 0, amount: 0.0)

      def +(other) = with(count: count + other.count, amount: amount + other.amount)
    end

    Row = Data.define(:user, :by_type) do
      def total = by_type.values.reduce(Stat.empty, :+)
    end

    def initialize(range, now: Time.current)
      @range = range.first..[ range.last, now ].min
    end

    # Du joueur qui a le plus payé au joueur qui a le moins payé.
    def rows
      @rows ||= begin
        stats = stats_by_user
        users = User.where(id: stats.keys).index_by(&:id)
        stats.map { |user_id, by_type| Row.new(user: users.fetch(user_id), by_type:) }
             .sort_by { |row| -row.total.amount }
      end
    end

    def session_types
      rows.flat_map { |row| row.by_type.keys }.uniq.sort_by { |type| Session.session_types.keys.index(type) }
    end

    def totals
      session_types.index_with { |type| rows.map { |row| row.by_type.fetch(type, Stat.empty) }.reduce(Stat.empty, :+) }
    end

    private

    def stats_by_user
      paid_sessions.each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |(user_id, type, credits), stats|
        stat = Stat.new(count: 1, amount: credits.to_f / CreditPurchase::CREDITS_PER_EUR)
        stats[user_id][type] = stats[user_id].fetch(type, Stat.empty) + stat
      end
    end

    # Une ligne par (joueur, session) payée : paiements et remboursements se compensent.
    def paid_sessions
      CreditTransaction.revenue_transactions
        .joins(:session)
        .where(sessions: { start_at: @range })
        .group(:user_id, :session_id, "sessions.session_type")
        .having("SUM(credit_transactions.amount) < 0")
        .pluck(:user_id, "sessions.session_type", Arel.sql("-SUM(credit_transactions.amount)"))
    end
  end
end
