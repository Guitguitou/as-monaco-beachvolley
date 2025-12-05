# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationService, type: :service do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }
  let(:session_record) do
    create(:session,
           session_type: 'entrainement',
           terrain: 'Terrain 1',
           user: coach,
           levels: [level])
  end

  before do
    create(:credit_transaction, user: player, amount: 1_000)
  end

  describe '#create' do
    it 'creates a confirmed registration and debits credits' do
      initial_balance = player.reload.balance.amount

      result = RegistrationService.new(
        session_record,
        player,
        can_bypass_deadline: false,
        can_register_private_coaching: false
      ).create(waitlist: false)

      expect(result[:success]).to be true
      expect(result[:registration]).to be_persisted
      expect(result[:registration].status).to eq('confirmed')
      expect(player.reload.balance.amount).to eq(initial_balance - session_record.price)
    end

    it 'creates a waitlisted registration without debiting credits' do
      initial_balance = player.reload.balance.amount

      result = RegistrationService.new(
        session_record,
        player,
        can_bypass_deadline: false,
        can_register_private_coaching: false
      ).create(waitlist: true)

      expect(result[:success]).to be true
      expect(result[:registration].status).to eq('waitlisted')
      expect(player.reload.balance.amount).to eq(initial_balance)
    end

    it 'handles registration deadline correctly' do
      session_record.update!(
        start_at: Time.current.change(hour: 19, min: 0),
        end_at: Time.current.change(hour: 20, min: 30)
      )
      travel_to(Time.current.change(hour: 18, min: 0)) # After 17h deadline

      result = RegistrationService.new(
        session_record,
        player,
        can_bypass_deadline: false,
        can_register_private_coaching: false
      ).create(waitlist: false)

      expect(result[:success]).to be false
      expect(result[:errors]).to include(match(/17h/))

      travel_back
    end

    it 'allows bypassing deadline when option is set' do
      session_record.update!(
        start_at: Time.current.change(hour: 19, min: 0),
        end_at: Time.current.change(hour: 20, min: 30)
      )
      travel_to(Time.current.change(hour: 18, min: 0))

      result = RegistrationService.new(
        session_record,
        player,
        can_bypass_deadline: true,
        can_register_private_coaching: false
      ).create(waitlist: false)

      expect(result[:success]).to be true

      travel_back
    end
  end

  describe '#destroy' do
    let!(:registration) do
      create(:registration, user: player, session: session_record, status: :confirmed)
    end

    it 'removes registration and refunds credits when refundable' do
      initial_balance = player.reload.balance.amount

      result = RegistrationService.new(
        session_record,
        player,
        can_manage_others_registrations: false,
        can_bypass_session_end: false
      ).destroy

      expect(result[:success]).to be true
      expect(Registration.exists?(registration.id)).to be false
      expect(player.reload.balance.amount).to eq(initial_balance + session_record.price)
    end

    it 'does not refund when past cancellation deadline' do
      session_record.update!(
        cancellation_deadline_at: 1.hour.ago
      )
      initial_balance = player.reload.balance.amount

      result = RegistrationService.new(
        session_record,
        player,
        can_manage_others_registrations: false,
        can_bypass_session_end: false
      ).destroy

      expect(result[:success]).to be true
      expect(player.reload.balance.amount).to eq(initial_balance)
      expect(LateCancellation.exists?(user: player, session: session_record)).to be true
    end

    it 'prevents unregistration after session end for non-admins' do
      session_record.update!(
        start_at: 2.hours.ago,
        end_at: 1.hour.ago
      )

      result = RegistrationService.new(
        session_record,
        player,
        can_manage_others_registrations: false,
        can_bypass_session_end: false
      ).destroy

      expect(result[:success]).to be false
      expect(result[:errors]).to include(match(/passée/))
    end
  end
end

