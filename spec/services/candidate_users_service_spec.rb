# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CandidateUsersService, type: :service do
  let(:coach) { create(:user, :coach) }
  let(:level1) { create(:level) }
  let(:level2) { create(:level) }
  let(:player1) { create(:user, level: level1) }
  let(:player2) { create(:user, level: level2) }
  let(:player3) { create(:user, level: level1) }
  let(:session_record) do
    create(:session,
           session_type: 'entrainement',
           terrain: 'Terrain 1',
           user: coach,
           levels: [level1],
           price: 100)
  end

  before do
    create(:credit_transaction, user: player1, amount: 1_000)
    create(:credit_transaction, user: player2, amount: 1_000)
    create(:credit_transaction, user: player3, amount: 50) # Not enough credits
  end

  describe '#call' do
    it 'excludes already registered users' do
      create(:registration, user: player1, session: session_record, status: :confirmed)

      service = CandidateUsersService.new(session_record)
      candidates = service.call

      expect(candidates).not_to include(player1)
    end

    it 'filters by level for training sessions' do
      service = CandidateUsersService.new(session_record)
      candidates = service.call

      expect(candidates).to include(player1)
      expect(candidates).not_to include(player2) # Different level
    end

    it 'filters by credits for non-private sessions' do
      service = CandidateUsersService.new(session_record)
      candidates = service.call

      expect(candidates).to include(player1)
      expect(candidates).not_to include(player3) # Not enough credits
    end

    it 'does not filter by credits for private coaching' do
      private_session = create(:session,
                                session_type: 'coaching_prive',
                                terrain: 'Terrain 1',
                                user: coach,
                                levels: [level1],
                                price: 1000)

      create(:credit_transaction, user: player3, amount: 50)

      service = CandidateUsersService.new(private_session)
      candidates = service.call

      expect(candidates).to include(player3) # Can join even with low credits
    end

    it 'excludes users with schedule conflicts when session is not full' do
      overlapping_session = create(:session,
                                   session_type: 'entrainement',
                                   terrain: 'Terrain 2',
                                   user: coach,
                                   levels: [level1],
                                   start_at: session_record.start_at + 5.minutes,
                                   end_at: session_record.end_at + 5.minutes)
      create(:registration, user: player1, session: overlapping_session, status: :confirmed)

      service = CandidateUsersService.new(session_record)
      candidates = service.call

      expect(candidates).not_to include(player1)
    end
  end
end

