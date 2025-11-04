# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it 'has many user_levels' do
      expect(user).to respond_to(:user_levels)
    end

    it 'has many levels through user_levels' do
      expect(user).to respond_to(:levels)
    end

    it 'has one balance' do
      expect(user).to respond_to(:balance)
    end

    it 'has many credit_transactions' do
      expect(user).to respond_to(:credit_transactions)
    end

    it 'has many credit_purchases' do
      expect(user).to respond_to(:credit_purchases)
    end

    it 'has many registrations' do
      expect(user).to respond_to(:registrations)
    end

    it 'has many confirmed_registrations' do
      expect(user).to respond_to(:confirmed_registrations)
    end

    it 'has many sessions_registered' do
      expect(user).to respond_to(:sessions_registered)
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'initializes balance with 0' do
        new_user = create(:user)
        expect(new_user.balance).to be_present
        expect(new_user.balance.amount).to eq(0)
      end

      it 'applies legacy level assignment if provided' do
        level = create(:level)
        new_user = User.create!(
          email: 'test@example.com',
          password: 'password123',
          first_name: 'John',
          last_name: 'Doe',
          level:
        )

        expect(new_user.levels).to include(level)
        expect(new_user.level).to eq(level)
      end
    end
  end

  describe 'scopes' do
    let!(:coach) { create(:user, coach: true, admin: false, responsable: false) }
    let!(:responsable) { create(:user, responsable: true, admin: false, coach: false) }
    let!(:admin) { create(:user, admin: true, coach: false, responsable: false) }
    let!(:regular_user) { create(:user, admin: false, coach: false, responsable: false) }

    describe '.coachs' do
      it 'returns only coaches' do
        expect(User.coachs).to include(coach)
        expect(User.coachs).not_to include(regular_user, responsable, admin)
      end
    end

    describe '.responsables' do
      it 'returns only responsables' do
        expect(User.responsables).to include(responsable)
        expect(User.responsables).not_to include(regular_user, coach, admin)
      end
    end

    describe '.admins' do
      it 'returns only admins' do
        expect(User.admins).to include(admin)
        expect(User.admins).not_to include(regular_user, coach, responsable)
      end
    end

    describe '.with_enough_credits' do
      let!(:rich_user) { create(:user) }
      let!(:poor_user) { create(:user) }
      let(:session_record) { create(:session) }  # Default price is 400 for training

      before do
        rich_user.balance.update!(amount: 500)   # More than session price
        poor_user.balance.update!(amount: 100)   # Less than session price
        rich_user.reload
        poor_user.reload
      end

      it 'returns users with sufficient credits' do
        result = User.with_enough_credits(session_record)

        # Verify session price is as expected (default training price)
        expect(session_record.price).to eq(400)

        # Check that rich_user has enough credits
        expect(rich_user.balance.amount).to eq(500)
        expect(rich_user.balance.amount).to be >= session_record.price

        # Check that poor_user doesn't have enough credits
        expect(poor_user.balance.amount).to eq(100)
        expect(poor_user.balance.amount).to be < session_record.price

        # Verify the scope includes rich_user and excludes poor_user
        expect(result.pluck(:id)).to include(rich_user.id)
        expect(result.pluck(:id)).not_to include(poor_user.id)

        # Verify the scope logic: all returned users have enough credits
        result.each do |u|
          expect(u.balance.amount).to be >= session_record.price
        end
      end
    end
  end

  describe 'Account activation' do
    describe '#activated?' do
      it 'returns true when activated_at is present' do
        user.update!(activated_at: Time.current)
        expect(user.activated?).to be true
      end

      it 'returns false when activated_at is nil' do
        user.update!(activated_at: nil)
        expect(user.activated?).to be false
      end
    end

    describe '#activate!' do
      it 'sets activated_at to current time' do
        user.update!(activated_at: nil)
        
        expect {
          user.activate!
        }.to change { user.reload.activated_at }.from(nil)

        expect(user.activated?).to be true
      end

      it 'does not update if already activated' do
        original_time = 1.day.ago
        user.update!(activated_at: original_time)

        user.activate!

        expect(user.reload.activated_at).to be_within(1.second).of(original_time)
      end
    end

    describe 'scopes' do
      let!(:activated_user) { create(:user, activated_at: Time.current) }
      let!(:not_activated_user) { create(:user, activated_at: nil) }

      describe '.activated' do
        it 'returns only activated users' do
          expect(User.activated).to include(activated_user)
          expect(User.activated).not_to include(not_activated_user)
        end
      end

      describe '.not_activated' do
        it 'returns only non-activated users' do
          expect(User.not_activated).to include(not_activated_user)
          expect(User.not_activated).not_to include(activated_user)
        end
      end
    end
  end

  describe 'Devise authentication with Disableable and Activation' do
    describe '#active_for_authentication?' do
      context 'when user is not disabled and activated' do
        before { user.update!(disabled_at: nil, activated_at: Time.current) }

        it 'returns true' do
          expect(user.active_for_authentication?).to be true
        end
      end

      context 'when user is disabled' do
        before { user.update!(disabled_at: Time.current, activated_at: Time.current) }

        it 'returns false even if activated' do
          expect(user.active_for_authentication?).to be false
        end
      end

      context 'when user is not activated' do
        before { user.update!(disabled_at: nil, activated_at: nil) }

        it 'returns false even if not disabled' do
          expect(user.active_for_authentication?).to be false
        end
      end
    end

    describe '#inactive_message' do
      context 'when user is disabled' do
        before { user.update!(disabled_at: Time.current, activated_at: Time.current) }

        it 'returns :locked' do
          expect(user.inactive_message).to eq(:locked)
        end
      end

      context 'when user is not activated' do
        before { user.update!(disabled_at: nil, activated_at: nil) }

        it 'returns :inactive' do
          expect(user.inactive_message).to eq(:inactive)
        end
      end

      context 'when user is activated and not disabled' do
        before { user.update!(disabled_at: nil, activated_at: Time.current) }

        it 'returns default devise message' do
          # Devise default behavior
          expect(user.inactive_message).to be_in([:inactive, nil])
        end
      end
    end
  end

  describe '#full_name' do
    it 'returns first and last name concatenated' do
      user.update!(first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#credit_balance' do
    it 'returns balance amount' do
      user.balance.update!(amount: 100)
      expect(user.credit_balance).to eq(100)
    end

    it 'returns 0 when balance is nil' do
      user.balance.destroy
      expect(user.credit_balance).to eq(0)
    end

    it 'reflects changes from credit transactions' do
      create(:credit_transaction, user:, amount: 100)
      create(:credit_transaction, user:, amount: -50)

      expect(user.reload.credit_balance).to eq(50)
      expect(user.balance.amount).to eq(50)
    end
  end

  describe '#level and #level=' do
    let(:level1) { create(:level) }
    let(:level2) { create(:level) }

    describe '#level' do
      it 'returns the first level' do
        user.levels << [level1, level2]
        expect(user.level).to eq(level1)
      end

      it 'returns nil when user has no levels' do
        expect(user.level).to be_nil
      end
    end

    describe '#level=' do
      it 'assigns level for legacy compatibility' do
        new_user = User.new(
          email: 'legacy@example.com',
          password: 'password123',
          first_name: 'Legacy',
          last_name: 'User'
        )
        new_user.level = level1
        new_user.save!

        expect(new_user.reload.levels).to include(level1)
      end
    end
  end

  describe 'salary helpers' do
    describe '#salary_per_training' do
      it 'converts cents to euros' do
        user.update!(salary_per_training_cents: 2500)
        expect(user.salary_per_training).to eq(25.0)
      end

      it 'returns 0 when salary_per_training_cents is 0' do
        user.update!(salary_per_training_cents: 0)
        expect(user.salary_per_training).to eq(0.0)
      end
    end

    describe '#salary_per_training=' do
      it 'converts euros to cents and stores' do
        user.salary_per_training = 35.50
        expect(user.salary_per_training_cents).to eq(3550)
      end

      it 'rounds to nearest cent' do
        user.salary_per_training = 35.556
        expect(user.salary_per_training_cents).to eq(3556)
      end

      it 'handles zero' do
        user.salary_per_training = 0
        expect(user.salary_per_training_cents).to eq(0)
      end
    end
  end
end
