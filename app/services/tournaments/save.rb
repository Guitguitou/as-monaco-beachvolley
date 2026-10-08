# frozen_string_literal: true

module Tournaments
  # Enregistre un tournoi avec ce qui en dérive : son Pack tournoi (fermé à la
  # création, l'admin ouvre le paiement) et une Session tournoi par terrain et
  # par jour. Les sessions sont recréées à chaque enregistrement ; si l'une
  # chevauche l'agenda, rien n'est enregistré.
  class Save
    def initialize(tournament:, owner:)
      @tournament = tournament
      @owner = owner
    end

    def call
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless tournament.save && sync_pack && sync_sessions
      end
      tournament.errors.empty?
    end

    private

    attr_reader :tournament, :owner

    def sync_pack
      pack = tournament.pack || Pack.new(tournament_id: tournament.id, pack_type: :inscription_tournoi, active: false)
      pack.assign_attributes(name: tournament.title, amount_cents: tournament.price_cents)
      return true if pack.save

      tournament.errors.add(:base, "Pack tournoi : #{pack.errors.full_messages.to_sentence}")
      false
    end

    def sync_sessions
      tournament.sessions.destroy_all
      tournament.days.product(tournament.terrain_names).all? do |day, terrain|
        session = Session.new(session_attributes(day, terrain))
        next true if session.save

        tournament.errors.add(:base, "#{terrain} le #{I18n.l(day)} : #{session.errors.full_messages.to_sentence}")
        false
      end
    end

    def session_attributes(day, terrain)
      {
        tournament_id: tournament.id,
        title: tournament.title,
        session_type: "tournoi",
        terrain: terrain,
        user: owner,
        start_at: at(day, tournament.start_time),
        end_at: at(day, tournament.end_time)
      }
    end

    def at(day, time)
      Time.zone.local(day.year, day.month, day.day, time.hour, time.min)
    end
  end
end
