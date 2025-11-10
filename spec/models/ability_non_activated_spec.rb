# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability, 'Non-activated users' do
  let(:non_activated_user) { create(:user, activated_at: nil) }
  let(:activated_user) { create(:user, activated_at: Time.current) }
  let(:admin_user) { create(:user, admin: true) }

  let(:credits_pack) { create(:pack, pack_type: :credits, credits: 100, amount_cents: 1000) }
  let(:licence_pack) { create(:pack, pack_type: :licence, amount_cents: 5000) }
  let(:stage) { create(:stage) }
  let(:stage_pack) { create(:pack, pack_type: :stage, stage: stage, amount_cents: 10000) }

  describe 'Non-activated user permissions' do
    subject(:ability) { Ability.new(non_activated_user) }

    it 'can read licence packs' do
      expect(ability).to be_able_to(:read, licence_pack)
    end

    it 'can buy licence packs' do
      expect(ability).to be_able_to(:buy, licence_pack)
    end

    it 'can read stage packs' do
      expect(ability).to be_able_to(:read, stage_pack)
    end

    it 'can buy stage packs' do
      expect(ability).to be_able_to(:buy, stage_pack)
    end

    it 'can read stages' do
      expect(ability).to be_able_to(:read, stage)
    end

    it 'cannot read credits packs' do
      expect(ability).not_to be_able_to(:read, credits_pack)
    end

    it 'cannot buy credits packs' do
      expect(ability).not_to be_able_to(:buy, credits_pack)
    end

    it 'cannot read sessions' do
      session = create(:session, :jeu_libre, user: create(:user, coach: true))
      expect(ability).not_to be_able_to(:read, session)
    end

    it 'cannot create registrations' do
      expect(ability).not_to be_able_to(:create, Registration)
    end
  end

  describe 'Activated user permissions' do
    subject(:ability) { Ability.new(activated_user) }

    it 'can read all packs' do
      expect(ability).to be_able_to(:read, credits_pack)
      expect(ability).to be_able_to(:read, licence_pack)
      expect(ability).to be_able_to(:read, stage_pack)
    end

    it 'can buy all packs' do
      expect(ability).to be_able_to(:buy, credits_pack)
      expect(ability).to be_able_to(:buy, licence_pack)
      expect(ability).to be_able_to(:buy, stage_pack)
    end

    it 'can read sessions' do
      session = create(:session, :jeu_libre, user: create(:user, coach: true))
      expect(ability).to be_able_to(:read, session)
    end

    it 'can create registrations' do
      expect(ability).to be_able_to(:create, Registration)
    end
  end

  describe 'Admin permissions' do
    subject(:ability) { Ability.new(admin_user) }

    it 'can manage everything' do
      expect(ability).to be_able_to(:manage, :all)
    end
  end
end

