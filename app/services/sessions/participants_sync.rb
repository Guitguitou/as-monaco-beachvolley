# frozen_string_literal: true

module Sessions
  # Aligne les inscrits d'une session sur la liste choisie dans le formulaire :
  # inscrit et débite les nouveaux, désinscrit les retirés (cf. Registrations::Cancellation).
  # Renvoie les erreurs d'inscription, une par participant refusé.
  class ParticipantsSync
    def initialize(session:, allow_private_coaching:, bypass_deadline: false)
      @session = session
      @allow_private_coaching = allow_private_coaching
      @bypass_deadline = bypass_deadline
    end

    # excused_ids : retirés dont le Staff excuse la désinscription tardive.
    def call(participant_ids, excused_ids: [])
      wanted_ids = ids(participant_ids)
      excused = ids(excused_ids)
      current_ids = @session.participants.pluck(:id)

      errors = (wanted_ids - current_ids).filter_map { |user_id| add(user_id) }
      (current_ids - wanted_ids).each { |user_id| remove(user_id, excused: excused.include?(user_id)) }
      errors
    end

    private

    # Renvoie un message d'erreur si l'inscription échoue, nil sinon.
    def add(user_id)
      registration = Registration.new(user_id: user_id, session: @session, status: :confirmed)
      registration.allow_private_coaching_registration = true if @session.coaching_prive? && @allow_private_coaching
      registration.allow_deadline_bypass = true if @bypass_deadline
      ActiveRecord::Base.transaction do
        registration.save!
        amount = registration.required_credits_for(registration.user)
        TransactionService.new(registration.user, @session, amount).create_transaction if amount.positive?
      end
      nil
    rescue StandardError => e
      "#{User.find(user_id).full_name}: #{registration.errors.full_messages.presence || e.message}"
    end

    def remove(user_id, excused:)
      registration = @session.registrations.find_by(user_id: user_id)
      Registrations::Cancellation.new(registration, excused: excused).call if registration
    end

    def ids(values)
      Array(values).reject(&:blank?).map(&:to_i)
    end
  end
end
