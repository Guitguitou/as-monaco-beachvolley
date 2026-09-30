require 'rails_helper'

RSpec.describe Annonce, type: :model do
  describe 'validations' do
    it 'is valid with a title and at least one slot' do
      annonce = build(:annonce, :with_slot)
      expect(annonce).to be_valid
    end

    it 'derives a title from the first slot when none is given' do
      start_at = Time.zone.local(2030, 10, 5, 10, 0)
      annonce = build(:annonce, title: nil, slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ])
      expect(annonce).to be_valid
      expect(annonce.title).to eq("Jeu libre · sam 5 oct, matin")
    end

    it 'is invalid without any slot' do
      annonce = build(:annonce)
      expect(annonce).not_to be_valid
      expect(annonce.errors[:base]).to include("Une partie doit proposer au moins un créneau")
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

RSpec.describe Annonce, "créneaux passés", type: :model do
  let(:annonce) { create(:annonce, :with_slot, min_players: 1) }
  let(:slot) { annonce.slots.first }

  it "n'est plus confirmable une fois le créneau passé" do
    create(:annonce_availability, annonce_slot: slot)
    slot.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 2.hours)

    expect(annonce.reload.confirmable_slots).to be_empty
    expect(annonce.upcoming_slots).to be_empty
  end

  it "est repérée par without_upcoming_slot" do
    past = create(:annonce, :with_slot)
    past.slots.first.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 2.hours)

    expect(Annonce.without_upcoming_slot).to contain_exactly(past)
    expect(Annonce.without_upcoming_slot).not_to include(annonce)
  end
end
