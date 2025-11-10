require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:level) { create(:level) }
  let(:user)  { create(:user, level: level) }
  # Create session tomorrow at 19h to avoid registration deadline issues
  let(:tomorrow_7pm) { (Time.current + 1.day).change(hour: 19, min: 0) }
  let(:session) { create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 1', start_at: tomorrow_7pm, end_at: tomorrow_7pm + 1.5.hours) }

  before do
    # Ensure users used in tests have enough credits unless explicitly testing insufficient credits
    create(:credit_transaction, user: user, amount: 10_000)
  end

  describe 'validations' do
    it 'is invalid if session is full' do
      session.update!(max_players: 1)
      create(:registration, user: user, session: session)
      other_user = create(:user, level: level)
      create(:credit_transaction, user: other_user, amount: 10_000)
      other = build(:registration, user: other_user, session: session)
      expect(other).not_to be_valid
      expect(other.errors[:base]).to include("Session complète.")
    end

    it 'is invalid if user level not allowed' do
      wrong_user = create(:user, level: create(:level))
      create(:credit_transaction, user: wrong_user, amount: 10_000)
      reg = build(:registration, user: wrong_user, session: session)
      expect(reg).not_to be_valid
      expect(reg.errors[:base]).to include("Ce n’est pas ton niveau d'entrainement.")
    end

    it 'requires enough credits when needed' do
      allow_any_instance_of(Balance).to receive(:amount).and_return(0)
      reg = build(:registration, user: user, session: session)
      expect(reg).not_to be_valid
      expect(reg.errors[:base]).to include("Pas assez de crédits.")
    end

    it 'disallows confirmed registration when overlapping with another confirmed session' do
      other_session = create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 2', start_at: tomorrow_7pm + 10.minutes, end_at: tomorrow_7pm + 1.5.hours + 10.minutes)
      create(:registration, user: user, session: session, status: :confirmed)
      reg = build(:registration, user: user, session: other_session, status: :confirmed)
      expect(reg).not_to be_valid
      expect(reg.errors[:base]).to include("Tu es déjà inscrit à une autre session sur le même créneau.")
    end

    it 'allows waitlisted registration even if overlapping' do
      other_session = create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 2', start_at: tomorrow_7pm + 10.minutes, end_at: tomorrow_7pm + 1.5.hours + 10.minutes)
      create(:registration, user: user, session: session, status: :confirmed)
      reg = build(:registration, user: user, session: other_session, status: :waitlisted)
      expect(reg).to be_valid
    end
  end

  describe 'weekly training limit' do
    let(:monday) { Time.zone.parse('2025-10-06 10:00:00') } # Monday
    let(:next_week_monday) { monday + 7.days }

    around do |example|
      travel_to monday do
        example.run
      end
    end

    it 'allows multiple training registrations in the current week' do
      s1 = create(:session, session_type: 'entrainement', start_at: monday.change(hour: 10), end_at: monday.change(hour: 11), terrain: 'Terrain 1', levels: [level])
      s2 = create(:session, session_type: 'entrainement', start_at: monday.change(hour: 18), end_at: monday.change(hour: 19), terrain: 'Terrain 2', levels: [level])

      create(:registration, user: user, session: s1, status: :confirmed)
      reg = build(:registration, user: user, session: s2, status: :confirmed)

      expect(reg).to be_valid
    end

    it 'disallows a second training in a non-current week' do
      # Current week: 2025-10-06 .. 2025-10-12
      # Target week for rule: next week
      s1 = create(:session, session_type: 'entrainement', start_at: next_week_monday.change(hour: 10), end_at: next_week_monday.change(hour: 11), terrain: 'Terrain 1', levels: [level], registration_opens_at: next_week_monday.change(hour: 0) - 8.days)
      s2 = create(:session, session_type: 'entrainement', start_at: next_week_monday.change(hour: 18), end_at: next_week_monday.change(hour: 19), terrain: 'Terrain 2', levels: [level], registration_opens_at: next_week_monday.change(hour: 0) - 8.days)

      create(:registration, user: user, session: s1, status: :confirmed)
      reg = build(:registration, user: user, session: s2, status: :confirmed)

      expect(reg).not_to be_valid
      expect(reg.errors[:base].join).to include("Tu as déjà un entraînement sur cette semaine")
    end

    it 'does not affect non-training sessions' do
      s1 = create(:session, session_type: 'jeu_libre', start_at: next_week_monday.change(hour: 10), end_at: next_week_monday.change(hour: 11), terrain: 'Terrain 1')
      s2 = create(:session, session_type: 'jeu_libre', start_at: next_week_monday.change(hour: 18), end_at: next_week_monday.change(hour: 19), terrain: 'Terrain 2')

      create(:registration, user: user, session: s1, status: :confirmed)
      reg = build(:registration, user: user, session: s2, status: :confirmed)

      expect(reg).to be_valid
    end
  end

  describe '#required_credits_for' do
    it 'returns 0 for coaching_prive' do
      coach = create(:user)
      create(:credit_transaction, user: coach, amount: 2_000)
      s = create(:session, user: coach, session_type: 'coaching_prive', terrain: 'Terrain 1')
      r = build(:registration, user: user, session: s)
      expect(r.required_credits_for(user)).to eq(0)
    end

    it 'returns session price otherwise' do
      r = build(:registration, user: user, session: session)
      expect(r.required_credits_for(user)).to eq(session.price)
    end
  end
end
