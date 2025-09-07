# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Session, type: :model do
  # ... existing tests ...

  describe 'scopes' do
    let(:coach) { create(:user, coach: true) }
    let(:current_time) { Time.zone.now }
    let(:week_start) { current_time.beginning_of_week }
    let(:month_start) { current_time.beginning_of_month }
    let(:year_start) { current_time.beginning_of_year }
    
    before do
      # Give coach enough credits for private coaching
      coach.balance.update!(amount: 2000)
    end

    let!(:upcoming_training) { create(:session, session_type: 'entrainement', start_at: current_time + 1.day + 10.hours, end_at: current_time + 1.day + 12.hours, user: coach) }
    let!(:past_training) { create(:session, session_type: 'entrainement', start_at: current_time - 1.day + 10.hours, end_at: current_time - 1.day + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:upcoming_free_play) { create(:session, session_type: 'jeu_libre', start_at: current_time + 1.day + 14.hours, end_at: current_time + 1.day + 16.hours, user: coach, terrain: 'Terrain 3') }
    let!(:upcoming_private_coaching) { create(:session, session_type: 'coaching_prive', start_at: current_time + 1.day + 18.hours, end_at: current_time + 1.day + 20.hours, user: coach) }
    let!(:week_training) { create(:session, session_type: 'entrainement', start_at: week_start + 2.days + 10.hours, end_at: week_start + 2.days + 12.hours, user: coach) }
    let!(:month_training) { create(:session, session_type: 'entrainement', start_at: month_start + 20.days + 10.hours, end_at: month_start + 20.days + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:year_training) { create(:session, session_type: 'entrainement', start_at: year_start + 60.days + 10.hours, end_at: year_start + 60.days + 12.hours, user: coach, terrain: 'Terrain 3') }

    describe '.upcoming' do
      it 'returns sessions starting from now' do
        result = Session.upcoming
        expect(result).to include(upcoming_training, upcoming_free_play, upcoming_private_coaching)
        expect(result).not_to include(past_training)
      end
    end

    describe '.in_week' do
      it 'returns sessions within the specified week' do
        result = Session.in_week(week_start)
        expect(result).to include(week_training)
        expect(result).not_to include(month_training, year_training)
      end
    end

    describe '.in_month' do
      it 'returns sessions within the specified month' do
        result = Session.in_month(month_start)
        expect(result).to include(month_training, week_training)
        expect(result).not_to include(year_training)
      end
    end

    describe '.in_year' do
      it 'returns sessions within the specified year' do
        result = Session.in_year(year_start)
        expect(result).to include(year_training, month_training, week_training)
      end
    end

    describe '.trainings' do
      it 'returns only training sessions' do
        result = Session.trainings
        expect(result).to include(upcoming_training, past_training, week_training)
        expect(result).not_to include(upcoming_free_play, upcoming_private_coaching)
      end
    end

    describe '.free_plays' do
      it 'returns only free play sessions' do
        result = Session.free_plays
        expect(result).to include(upcoming_free_play)
        expect(result).not_to include(upcoming_training, upcoming_private_coaching)
      end
    end

    describe '.private_coachings' do
      it 'returns only private coaching sessions' do
        result = Session.private_coachings
        expect(result).to include(upcoming_private_coaching)
        expect(result).not_to include(upcoming_training, upcoming_free_play)
      end
    end

    describe '.ordered_by_start' do
      it 'orders sessions by start_at' do
        session_1 = create(:session, session_type: 'entrainement', start_at: current_time + 3.days + 10.hours, end_at: current_time + 3.days + 12.hours, user: coach, terrain: 'Terrain 1')
        session_2 = create(:session, session_type: 'entrainement', start_at: current_time + 1.day + 10.hours, end_at: current_time + 1.day + 12.hours, user: coach, terrain: 'Terrain 2')
        session_3 = create(:session, session_type: 'entrainement', start_at: current_time + 2.days + 10.hours, end_at: current_time + 2.days + 12.hours, user: coach, terrain: 'Terrain 3')

        result = Session.where(id: [session_1.id, session_2.id, session_3.id]).ordered_by_start
        expect(result.to_a).to eq([session_2, session_3, session_1])
      end
    end
  end
end
