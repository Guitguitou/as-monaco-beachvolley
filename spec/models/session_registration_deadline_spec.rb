# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Session, 'Registration Deadline' do
  let(:coach) { create(:user, coach: true, salary_per_training_cents: 5000) }
  let(:regular_user) { create(:user, license_type: 'competition') }
  let(:today) { Time.zone.parse('2024-11-07 10:00:00') } # Jeudi 7 nov à 10h

  before do
    travel_to(today)
  end

  after do
    travel_back
  end

  describe '#past_registration_deadline?' do
    context 'for a training session today at 19h' do
      let(:session) do
        create(:session,
               session_type: 'entrainement',
               start_at: today.change(hour: 19, min: 0), # 19h aujourd'hui
               end_at: today.change(hour: 20, min: 30),
               user: coach)
      end

      context 'when current time is before 17h' do
        before { travel_to(today.change(hour: 16, min: 0)) } # 16h

        it 'returns false' do
          expect(session.past_registration_deadline?).to be false
        end
      end

      context 'when current time is exactly 17h' do
        before { travel_to(today.change(hour: 17, min: 0)) } # 17h

        it 'returns true' do
          expect(session.past_registration_deadline?).to be true
        end
      end

      context 'when current time is after 17h' do
        before { travel_to(today.change(hour: 18, min: 0)) } # 18h

        it 'returns true' do
          expect(session.past_registration_deadline?).to be true
        end
      end
    end

    context 'for a training session tomorrow' do
      let(:session) do
        create(:session,
               session_type: 'entrainement',
               start_at: (today + 1.day).change(hour: 19, min: 0), # Demain 19h
               end_at: (today + 1.day).change(hour: 20, min: 30),
               user: coach)
      end

      it 'returns false when today at 16h' do
        travel_to(today.change(hour: 16, min: 0))
        expect(session.past_registration_deadline?).to be false
      end

      it 'returns false when today at 18h' do
        travel_to(today.change(hour: 18, min: 0))
        expect(session.past_registration_deadline?).to be false
      end
    end

    context 'for a jeu libre session' do
      let(:session) do
        create(:session, :jeu_libre,
               start_at: today.change(hour: 19, min: 0),
               end_at: today.change(hour: 20, min: 30),
               user: coach)
      end

      it 'returns false (no deadline check for jeu libre)' do
        travel_to(today.change(hour: 18, min: 0))
        # Jeu libre doesn't use this, but method should still work
        expect(session.past_registration_deadline?).to be true
      end
    end
  end

  describe '#registration_open_state_for' do
    let(:session) do
      create(:session,
             session_type: 'entrainement',
             start_at: today.change(hour: 19, min: 0), # 19h aujourd'hui
             end_at: today.change(hour: 20, min: 30),
             user: coach,
             registration_opens_at: today.change(hour: 9, min: 0)) # Ouverture à 9h
    end

    context 'before 17h' do
      before { travel_to(today.change(hour: 16, min: 0)) }

      it 'allows registration' do
        can_register, reason = session.registration_open_state_for(regular_user)
        expect(can_register).to be true
        expect(reason).to be_nil
      end
    end

    context 'after 17h' do
      before { travel_to(today.change(hour: 18, min: 0)) }

      it 'blocks registration with deadline message' do
        can_register, reason = session.registration_open_state_for(regular_user)
        expect(can_register).to be false
        expect(reason).to include("Les inscriptions sont closes")
        expect(reason).to include("17h")
      end
    end

    context 'for jeu libre sessions' do
      let(:jeu_libre_session) do
        create(:session, :jeu_libre,
               start_at: today.change(hour: 19, min: 0),
               end_at: today.change(hour: 20, min: 30),
               user: coach)
      end

      before { travel_to(today.change(hour: 18, min: 0)) }

      it 'allows registration (no deadline for jeu libre)' do
        can_register, reason = jeu_libre_session.registration_open_state_for(regular_user)
        expect(can_register).to be true
        expect(reason).to be_nil
      end
    end
  end
end
