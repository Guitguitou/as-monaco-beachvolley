# frozen_string_literal: true

module Sessions
  # Invitations à un jeu libre : qui peut inviter, qui peut être invité, et
  # l'envoi lui-même (une notification push par invité, en tâche de fond).
  #
  # Inviter est réservé aux joueurs déjà inscrits (ou en attente) et à
  # l'organisateur : on invite à une partie dont on fait partie.
  class Invitations
    MAX_PER_INVITER = 10

    Result = Data.define(:sent, :message) do
      def success? = sent.positive?
    end

    def initialize(session:, inviter:)
      @session = session
      @inviter = inviter
    end

    def allowed?
      return false unless @session.jeu_libre? && @session.start_at > Time.current
      return true if @inviter.admin? || @session.user_id == @inviter.id

      Registration.exists?(session_id: @session.id, user_id: @inviter.id)
    end

    # Membres activés, ni inscrits, ni déjà invités, ni soi-même.
    def invitable_users
      User.activated
        .where.not(id: @inviter.id)
        .where.not(id: Registration.where(session_id: @session.id).select(:user_id))
        .where.not(id: SessionInvitation.where(session_id: @session.id).select(:invitee_id))
        .order(:first_name, :last_name)
    end

    def remaining
      [ MAX_PER_INVITER - SessionInvitation.where(session_id: @session.id, inviter_id: @inviter.id).count, 0 ].max
    end

    def invite(invitee_ids, url:)
      return Result.new(sent: 0, message: "Tu ne peux pas inviter à cette session.") unless allowed?

      invitees = invitable_users.where(id: Array(invitee_ids)).limit(remaining).to_a
      return Result.new(sent: 0, message: "Aucun joueur à inviter.") if invitees.empty?

      invitees.each do |invitee|
        SessionInvitation.create!(session: @session, inviter: @inviter, invitee: invitee)
        SendPushNotificationJob.perform_later(invitee.id, title: notification_title, body: notification_body, url: url)
      end
      Result.new(sent: invitees.size, message: confirmation(invitees))
    end

    private

    def notification_title
      "#{@inviter.first_name.presence || @inviter.full_name} t'invite à jouer"
    end

    def notification_body
      "#{@session.title} · #{I18n.l(@session.start_at, format: :short)} · #{@session.terrain}"
    end

    def confirmation(invitees)
      names = invitees.map { |u| u.first_name.presence || u.full_name }
      "Invitation envoyée à #{names.to_sentence(locale: :fr)}."
    end
  end
end
