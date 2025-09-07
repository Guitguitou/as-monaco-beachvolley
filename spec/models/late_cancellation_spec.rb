# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LateCancellation, type: :model do
  # ... existing tests ...

  describe 'scopes' do
    let(:coach) { create(:user, coach: true) }
    let(:user) { create(:user) }
    
    before do
      # Give coach enough credits for private coaching
      coach.balance.update!(amount: 2000)
    end
    let!(:training) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach) }
    let!(:free_play) { create(:session, session_type: 'jeu_libre', start_at: 1.day.from_now + 14.hours, end_at: 1.day.from_now + 16.hours, user: coach, terrain: 'Terrain 2') }
    let!(:private_coaching) { create(:session, session_type: 'coaching_prive', start_at: 1.day.from_now + 18.hours, end_at: 1.day.from_now + 20.hours, user: coach, terrain: 'Terrain 3') }

    let!(:late_cancellation_training) { create(:late_cancellation, session: training, user: user) }
    let!(:late_cancellation_free_play) { create(:late_cancellation, session: free_play, user: user) }
    let!(:late_cancellation_private_coaching) { create(:late_cancellation, session: private_coaching, user: user) }

    describe '.for_trainings' do
      it 'returns only late cancellations for training sessions' do
        result = LateCancellation.for_trainings
        expect(result).to include(late_cancellation_training)
        expect(result).not_to include(late_cancellation_free_play, late_cancellation_private_coaching)
      end
    end

    describe '.recent' do
      it 'returns recent late cancellations ordered by created_at desc' do
        old_cancellation = create(:late_cancellation, session: training, user: user, created_at: 1.week.ago)
        recent_cancellation = create(:late_cancellation, session: free_play, user: user, created_at: 1.day.ago)

        result = LateCancellation.where(id: [old_cancellation.id, recent_cancellation.id]).recent(10)
        expect(result.first).to eq(recent_cancellation)
        expect(result.last).to eq(old_cancellation)
      end

      it 'limits results to specified number' do
        5.times { |i| create(:late_cancellation, session: i.even? ? training : free_play, user: user) }

        result = LateCancellation.recent(3)
        expect(result.count).to eq(3)
      end
    end

    describe '.with_associations' do
      it 'includes user and session associations' do
        result = LateCancellation.with_associations
        expect(result.first.association(:user)).to be_loaded
        expect(result.first.association(:session)).to be_loaded
      end
    end
  end
end
