require 'rails_helper'

RSpec.describe Annonce, type: :model do
  describe 'validations' do
    it 'is valid with a title and at least one slot' do
      annonce = build(:annonce, :with_slot)
      expect(annonce).to be_valid
    end

    it 'is invalid without a title' do
      annonce = build(:annonce, :with_slot, title: nil)
      expect(annonce).not_to be_valid
      expect(annonce.errors[:title]).to be_present
    end

    it 'is invalid without any slot' do
      annonce = build(:annonce)
      expect(annonce).not_to be_valid
      expect(annonce.errors[:base]).to include("Une annonce doit proposer au moins un créneau")
    end
  end

  describe '#confirmable_slots / #confirmable?' do
    let(:annonce) { create(:annonce, :with_slot, min_players: 2) }
    let(:slot) { annonce.slots.first }

    it 'is not confirmable below the quota' do
      create(:annonce_availability, annonce_slot: slot)
      expect(annonce.reload.confirmable_slots).to be_empty
      expect(annonce).not_to be_confirmable
    end

    it 'is confirmable once a slot reaches min_players' do
      2.times { create(:annonce_availability, annonce_slot: slot) }
      annonce.reload
      expect(annonce.confirmable_slots).to include(slot)
      expect(annonce).to be_confirmable
    end

    it 'is not confirmable when the annonce is not open' do
      2.times { create(:annonce_availability, annonce_slot: slot) }
      annonce.update!(status: :cancelled)
      expect(annonce.reload).not_to be_confirmable
    end
  end

  describe '#responsable_present?' do
    let(:annonce) { create(:annonce, :with_slot) }
    let(:slot) { annonce.slots.first }

    it 'is true when a responsable is available on the slot' do
      create(:annonce_availability, annonce_slot: slot, user: create(:user, :responsable))
      expect(annonce.responsable_present?(slot.reload)).to be(true)
    end

    it 'is false with only regular players' do
      create(:annonce_availability, annonce_slot: slot, user: create(:user))
      expect(annonce.responsable_present?(slot.reload)).to be(false)
    end
  end

  describe '#participant_count' do
    it 'counts distinct users across slots' do
      annonce = create(:annonce, :with_slot)
      slot = annonce.slots.first
      user = create(:user)
      create(:annonce_availability, annonce_slot: slot, user: user)
      create(:annonce_availability, annonce_slot: slot, user: create(:user))
      expect(annonce.participant_count).to eq(2)
    end
  end
end
