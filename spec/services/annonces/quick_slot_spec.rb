# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::QuickSlot do
  # Mercredi 1er octobre 2031, 10h.
  let(:wednesday) { Time.zone.local(2031, 10, 1, 10, 0) }

  it "propose ce soir, demain soir et le week-end à venir" do
    slots = described_class.available(now: wednesday)

    expect(slots.map(&:key)).to eq(%w[ce_soir demain_soir samedi_matin dimanche_matin])
    expect(slots.first.start_at).to eq(Time.zone.local(2031, 10, 1, 19, 0))
    expect(slots.first.end_at).to eq(Time.zone.local(2031, 10, 1, 21, 0))
    expect(slots.find { |slot| slot.key == "samedi_matin" }.start_at).to eq(Time.zone.local(2031, 10, 4, 10, 0))
  end

  it "retire ce soir quand il ne reste plus le temps de réunir des joueurs" do
    slots = described_class.available(now: wednesday.change(hour: 17, min: 30))

    expect(slots.map(&:key)).not_to include("ce_soir")
  end

  it "passe au week-end suivant quand samedi matin est trop proche" do
    saturday = Time.zone.local(2031, 10, 4, 9, 0)

    samedi = described_class.find("samedi_matin", now: saturday)

    expect(samedi.start_at).to eq(Time.zone.local(2031, 10, 11, 10, 0))
  end

  it "ne trouve rien pour une clé inconnue" do
    expect(described_class.find("lundi_aube", now: wednesday)).to be_nil
  end
end
