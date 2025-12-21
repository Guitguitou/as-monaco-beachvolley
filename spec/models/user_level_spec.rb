# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserLevel, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to level' do
      expect(described_class.reflect_on_association(:level).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:level) { create(:level) }

    it 'validates uniqueness of user_id scoped to level_id' do
      create(:user_level, user: user, level: level)

      duplicate = build(:user_level, user: user, level: level)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows same user with different levels' do
      level2 = create(:level)
      create(:user_level, user: user, level: level)

      user_level2 = build(:user_level, user: user, level: level2)
      expect(user_level2).to be_valid
    end

    it 'allows same level with different users' do
      user2 = create(:user)
      create(:user_level, user: user, level: level)

      user_level2 = build(:user_level, user: user2, level: level)
      expect(user_level2).to be_valid
    end
  end
end
