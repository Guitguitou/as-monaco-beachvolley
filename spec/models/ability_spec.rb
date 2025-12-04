# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:financial_manager_user) { create(:user, financial_manager: true) }
  let(:coach_user) { create(:user, coach: true) }
  let(:responsable_user) { create(:user, responsable: true) }
  let(:disabled_user) { create(:user, disabled_at: Time.current) }
  let(:activated_user) { create(:user, activated_at: Time.current) }
  let(:non_activated_user) { create(:user, activated_at: nil) }

  describe 'with nil user' do
    subject(:ability) { Ability.new(nil) }

    it 'has no permissions' do
      expect(ability).not_to be_able_to(:read, User.new)
      expect(ability).not_to be_able_to(:read, Session.new)
    end
  end

  describe 'admin user' do
    subject(:ability) { Ability.new(admin_user) }

    it 'can manage everything' do
      expect(ability).to be_able_to(:manage, :all)
    end
  end

  describe 'financial manager user' do
    subject(:ability) { Ability.new(financial_manager_user) }

    it 'can read admin dashboard' do
      expect(ability).to be_able_to(:read, :admin_dashboard)
    end

    it 'can read credit purchases' do
      credit_purchase = create(:credit_purchase)
      expect(ability).to be_able_to(:read, credit_purchase)
    end

    it 'cannot manage sessions' do
      session = create(:session)
      expect(ability).not_to be_able_to(:manage, session)
    end
  end

  describe 'disabled user' do
    subject(:ability) { Ability.new(disabled_user) }

    it 'has no permissions' do
      expect(ability).not_to be_able_to(:read, User.new(id: disabled_user.id))
      expect(ability).not_to be_able_to(:read, Session.new)
    end
  end

  describe 'activated user' do
    subject(:ability) { Ability.new(activated_user) }

    it 'can read own user' do
      expect(ability).to be_able_to(:read, activated_user)
    end

    it 'cannot read other users' do
      other_user = create(:user)
      expect(ability).not_to be_able_to(:read, other_user)
    end

    it 'can read sessions' do
      session = create(:session)
      expect(ability).to be_able_to(:read, session)
    end

    it 'can read stages' do
      stage = create(:stage)
      expect(ability).to be_able_to(:read, stage)
    end

    it 'can read all packs' do
      stage = create(:stage)
      credits_pack = create(:pack, pack_type: :credits)
      licence_pack = create(:pack, pack_type: :licence)
      stage_pack = create(:pack, pack_type: :stage, stage: stage)
      
      expect(ability).to be_able_to(:read, credits_pack)
      expect(ability).to be_able_to(:read, licence_pack)
      expect(ability).to be_able_to(:read, stage_pack)
    end

    it 'can buy all packs' do
      stage = create(:stage)
      credits_pack = create(:pack, pack_type: :credits)
      licence_pack = create(:pack, pack_type: :licence)
      stage_pack = create(:pack, pack_type: :stage, stage: stage)
      
      expect(ability).to be_able_to(:buy, credits_pack)
      expect(ability).to be_able_to(:buy, licence_pack)
      expect(ability).to be_able_to(:buy, stage_pack)
    end

    it 'can create registrations' do
      expect(ability).to be_able_to(:create, Registration)
    end

    it 'can destroy own registrations' do
      session_record = create(:session, :jeu_libre)
      create(:credit_transaction, user: activated_user, amount: 1000)
      registration = create(:registration, user: activated_user, session: session_record)
      expect(ability).to be_able_to(:destroy, registration)
    end

    it 'cannot destroy other users registrations' do
      other_user = create(:user)
      session_record = create(:session, :jeu_libre)
      create(:credit_transaction, user: other_user, amount: 1000)
      registration = create(:registration, user: other_user, session: session_record)
      expect(ability).not_to be_able_to(:destroy, registration)
    end

    it 'can read own credit transactions' do
      transaction = create(:credit_transaction, user: activated_user)
      expect(ability).to be_able_to(:read, transaction)
    end

    it 'cannot read other users credit transactions' do
      other_user = create(:user)
      transaction = create(:credit_transaction, user: other_user)
      expect(ability).not_to be_able_to(:read, transaction)
    end
  end

  describe 'non-activated user' do
    subject(:ability) { Ability.new(non_activated_user) }

    it 'can read own user' do
      expect(ability).to be_able_to(:read, non_activated_user)
    end

    it 'can read stages' do
      stage = create(:stage)
      expect(ability).to be_able_to(:read, stage)
    end

    it 'can read licence packs' do
      licence_pack = create(:pack, pack_type: :licence)
      expect(ability).to be_able_to(:read, licence_pack)
    end

    it 'can buy licence packs' do
      licence_pack = create(:pack, pack_type: :licence)
      expect(ability).to be_able_to(:buy, licence_pack)
    end

    it 'can read stage packs' do
      stage = create(:stage)
      stage_pack = create(:pack, pack_type: :stage, stage: stage)
      expect(ability).to be_able_to(:read, stage_pack)
    end

    it 'can buy stage packs' do
      stage = create(:stage)
      stage_pack = create(:pack, pack_type: :stage, stage: stage)
      expect(ability).to be_able_to(:buy, stage_pack)
    end

    it 'cannot read credits packs' do
      credits_pack = create(:pack, pack_type: :credits)
      expect(ability).not_to be_able_to(:read, credits_pack)
    end

    it 'cannot buy credits packs' do
      credits_pack = create(:pack, pack_type: :credits)
      expect(ability).not_to be_able_to(:buy, credits_pack)
    end

    it 'cannot read sessions' do
      session = create(:session)
      expect(ability).not_to be_able_to(:read, session)
    end

    it 'cannot create registrations' do
      expect(ability).not_to be_able_to(:create, Registration)
    end
  end

  describe 'coach user' do
    subject(:ability) { Ability.new(coach_user) }

    before do
      coach_user.update!(activated_at: Time.current)
    end

    it 'can perform CRUD operations on sessions' do
      session = create(:session)
      expect(ability).to be_able_to(:read, session)
      expect(ability).to be_able_to(:create, Session)
      expect(ability).to be_able_to(:update, session)
      expect(ability).to be_able_to(:destroy, session)
    end

    it 'can cancel their own sessions' do
      own_session = create(:session, user: coach_user)
      expect(ability).to be_able_to(:cancel, own_session)
    end

    it 'cannot cancel other coaches sessions' do
      other_session = create(:session)
      expect(ability).not_to be_able_to(:cancel, other_session)
    end

    it 'can manage registrations' do
      user_with_credits = create(:user)
      session_record = create(:session, :jeu_libre)
      create(:credit_transaction, user: user_with_credits, amount: 1000)
      registration = create(:registration, user: user_with_credits, session: session_record)
      expect(ability).to be_able_to(:manage, registration)
    end
  end

  describe 'responsable user' do
    subject(:ability) { Ability.new(responsable_user) }

    before do
      responsable_user.update!(activated_at: Time.current)
    end

    it 'can perform CRUD operations on sessions' do
      session = create(:session)
      expect(ability).to be_able_to(:read, session)
      expect(ability).to be_able_to(:create, Session)
      expect(ability).to be_able_to(:update, session)
      expect(ability).to be_able_to(:destroy, session)
    end

    it 'can cancel their own sessions' do
      own_session = create(:session, user: responsable_user)
      expect(ability).to be_able_to(:cancel, own_session)
    end

    it 'cannot cancel other users sessions' do
      other_session = create(:session)
      expect(ability).not_to be_able_to(:cancel, other_session)
    end

    it 'can manage registrations' do
      user_with_credits = create(:user)
      session_record = create(:session, :jeu_libre)
      create(:credit_transaction, user: user_with_credits, amount: 1000)
      registration = create(:registration, user: user_with_credits, session: session_record)
      expect(ability).to be_able_to(:manage, registration)
    end
  end

  describe 'disabled coach' do
    subject(:ability) { Ability.new(disabled_coach) }

    let(:disabled_coach) { create(:user, coach: true, disabled_at: Time.current) }

    it 'cannot manage sessions' do
      session = create(:session)
      expect(ability).not_to be_able_to(:manage, session)
    end
  end
end

