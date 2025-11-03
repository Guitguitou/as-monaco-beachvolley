# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Disableable do
  let(:user) { create(:user) }

  describe '#disabled?' do
    context 'when disabled_at is nil' do
      it 'returns false' do
        user.update!(disabled_at: nil)
        expect(user.disabled?).to be false
      end
    end

    context 'when disabled_at is present' do
      it 'returns true' do
        user.update!(disabled_at: Time.current)
        expect(user.disabled?).to be true
      end
    end
  end

  describe '#disable!' do
    it 'sets disabled_at to current time' do
      expect do
        user.disable!
      end.to change { user.reload.disabled_at }.from(nil)

      expect(user.disabled?).to be true
    end

    it 'does not update if already disabled' do
      user.update!(disabled_at: 1.day.ago)
      original_time = user.disabled_at

      user.disable!

      expect(user.reload.disabled_at).to be_within(1.second).of(original_time)
    end
  end

  describe '#enable!' do
    it 'sets disabled_at to nil' do
      user.update!(disabled_at: Time.current)

      expect do
        user.enable!
      end.to change { user.reload.disabled_at }.to(nil)

      expect(user.disabled?).to be false
    end

    it 'does not update if already enabled' do
      user.update!(disabled_at: nil)

      expect do
        user.enable!
      end.not_to(change { user.reload.updated_at })
    end
  end

  describe 'scopes' do
    let!(:enabled_user1) { create(:user, disabled_at: nil) }
    let!(:enabled_user2) { create(:user, disabled_at: nil) }
    let!(:disabled_user1) { create(:user, disabled_at: 1.day.ago) }
    let!(:disabled_user2) { create(:user, disabled_at: Time.current) }

    describe '.enabled' do
      it 'returns only users with disabled_at nil' do
        expect(User.enabled).to include(enabled_user1, enabled_user2)
        expect(User.enabled).not_to include(disabled_user1, disabled_user2)
      end
    end

    describe '.disabled' do
      it 'returns only users with disabled_at present' do
        expect(User.disabled).to include(disabled_user1, disabled_user2)
        expect(User.disabled).not_to include(enabled_user1, enabled_user2)
      end
    end
  end
end
