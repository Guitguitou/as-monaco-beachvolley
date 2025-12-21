# frozen_string_literal: true

# Service to create sessions on all terrains
class CreateSessionsOnAllTerrainsService
  TERRAINS = [ "Terrain 1", "Terrain 2", "Terrain 3" ].freeze

  def initialize(session_params, participant_ids, current_user)
    @session_params = session_params.to_h
    @session_params.delete("terrain")
    @participant_ids = participant_ids
    @current_user = current_user
  end

  def call
    created = []
    errors = []

    ActiveRecord::Base.transaction do
      TERRAINS.each do |terrain_label|
        session = create_session_for_terrain(terrain_label)
        if session.save
          created << session
          sync_participants_for(session)
        else
          errors << session.errors.full_messages.to_sentence
          raise ActiveRecord::Rollback
        end
      end
    end

    { success: errors.empty?, created: created, errors: errors }
  end

  private

  def create_session_for_terrain(terrain_label)
    session = Session.new(@session_params)
    session.terrain = terrain_label
    session
  end

  def sync_participants_for(session)
    return unless @participant_ids.present?

    SyncParticipantsService.new(
      session,
      @participant_ids,
      current_user: @current_user,
      can_manage_registration: true
    ).call
  end
end
