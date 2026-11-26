module Sessions
  # Fusion de séances (cf. GLOSSARY.md, ADR 0005) : la séance conservée reçoit
  # les groupes et les inscriptions de la séance absorbée, avec le coach et la
  # capacité choisis. La séance absorbée devient une séance annulée au motif
  # « fusionnée », sans remboursement ni excuse de ses désinscriptions tardives.
  class MergeService
    class Error < StandardError; end

    def self.call(kept:, absorbed:, coach:, max_players:)
      new(kept:, absorbed:, coach:, max_players:).call
    end

    def initialize(kept:, absorbed:, coach:, max_players:)
      @kept = kept
      @absorbed = absorbed
      @coach = coach
      @max_players = max_players.to_i
    end

    def call
      MergeEligibility.new(@kept, @absorbed).check!
      released_coaches = [ @kept.user, @absorbed.user ].uniq - [ @coach ]
      label = NotificationLabel.new(@kept)

      transferred = ActiveRecord::Base.transaction do
        check_capacity!
        drop_duplicates
        transfer_levels
        users = transfer_registrations
        @absorbed.update!(cancelled_at: Time.current, cancellation_reason: "fusionnee")
        @kept.reload.update!(user: @coach, max_players: @max_players, coach_notes: merged_notes)
        @kept.rebalance!
        users
      end

      notify(transferred, released_coaches, label)
      @kept
    end

    private

    def check_capacity!
      confirmed = Registration.confirmed.where(session_id: [ @kept.id, @absorbed.id ]).distinct.count(:user_id)
      return if @max_players >= confirmed

      raise Error, "La capacité (#{@max_players}) est inférieure aux #{confirmed} inscrits confirmés."
    end

    # Un joueur inscrit aux deux séances garde celle de la séance conservée.
    def drop_duplicates
      @absorbed.registrations.where(user_id: @kept.registrations.select(:user_id)).includes(:user).find_each do |registration|
        amount = registration.required_credits_for(registration.user)
        TransactionService.new(registration.user, @absorbed, amount).refund_transaction if amount.positive?
        registration.destroy!
      end
    end

    def transfer_levels
      kept_level_ids = @kept.session_levels.pluck(:level_id)
      @absorbed.session_levels.where.not(level_id: kept_level_ids).find_each do |session_level|
        @kept.session_levels.create!(level_id: session_level.level_id, priority: session_level.priority)
      end
    end

    def transfer_registrations
      registrations = @absorbed.registrations
      users = User.where(id: registrations.select(:user_id)).to_a
      registrations.update_all(session_id: @kept.id, updated_at: Time.current)
      users
    end

    def merged_notes
      [ @kept.coach_notes, @absorbed.coach_notes ].compact_blank.join("\n\n").presence
    end

    def notify(players, released_coaches, label)
      players.each { |player| SessionMailer.session_merged(player, @kept).deliver_later }
      released_coaches.each do |coach|
        SessionMailer.coach_released(coach, session_name: label.name, session_date: label.date).deliver_later
      end
    end
  end
end
