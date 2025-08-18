require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:level) { create(:level) }
  let(:user)  { create(:user, level: level) }
  let(:session) { create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 1') }

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
      other_session = create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 2', start_at: session.start_at + 10.minutes, end_at: session.end_at + 10.minutes)
      create(:registration, user: user, session: session, status: :confirmed)
      reg = build(:registration, user: user, session: other_session, status: :confirmed)
      expect(reg).not_to be_valid
      expect(reg.errors[:base]).to include("Tu es déjà inscrit à une autre session sur le même créneau.")
    end

    it 'allows waitlisted registration even if overlapping' do
      other_session = create(:session, session_type: 'entrainement', levels: [level], terrain: 'Terrain 2', start_at: session.start_at + 10.minutes, end_at: session.end_at + 10.minutes)
      create(:registration, user: user, session: session, status: :confirmed)
      reg = build(:registration, user: user, session: other_session, status: :waitlisted)
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
