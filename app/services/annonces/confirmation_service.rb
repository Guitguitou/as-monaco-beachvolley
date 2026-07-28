module Annonces
  # Transforme une annonce ouverte en une vraie Session de jeu libre sur le
  # créneau retenu et le terrain choisi, puis inscrit + débite les joueurs
  # disponibles sur ce créneau. Les joueurs insolvables ou en conflit d'agenda
  # sont ignorés (retournés dans `skipped`), sans faire échouer l'ensemble.
  #
  #   result = Annonces::ConfirmationService.new(annonce:, slot:, terrain:).call
  #   result.session   # la Session créée
  #   result.registered / result.skipped  # joueurs inscrits / ignorés
  class ConfirmationService
    Result = Struct.new(:session, :registered, :skipped, keyword_init: true)

    def initialize(annonce:, slot:, terrain:)
      @annonce = annonce
      @slot = slot
      @terrain = terrain
    end

    def call
      registered = []
      skipped = []
      session = nil

      ActiveRecord::Base.transaction do
        session = create_session!
        slot.available_users.each do |user|
          if register_player(user, session)
            registered << user
          else
            skipped << user
          end
        end
        annonce.update!(status: :confirmed, session: session)
      end

      Result.new(session: session, registered: registered, skipped: skipped)
    end

    private

    attr_reader :annonce, :slot, :terrain

    def create_session!
      Session.create!(
        title: annonce.title,
        description: annonce.description,
        session_type: :jeu_libre,
        start_at: slot.start_at,
        end_at: slot.end_at,
        terrain: terrain,
        user: annonce.user,
        max_players: slot.available_users.size
      )
    end

    # Inscription d'un joueur dans son propre savepoint : un échec (crédits
    # insuffisants, conflit d'agenda) ne rejette que ce joueur, pas la session.
    def register_player(user, session)
      ActiveRecord::Base.transaction(requires_new: true) do
        registration = Registration.new(user: user, session: session, status: :confirmed)
        registration.save!
        amount = registration.required_credits_for(user)
        TransactionService.new(user, session, amount).create_transaction if amount.positive?
      end
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid
      false
    end
  end
end
