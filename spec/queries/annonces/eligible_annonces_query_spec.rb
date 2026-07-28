require 'rails_helper'

RSpec.describe Annonces::EligibleAnnoncesQuery do
  let(:level)       { create(:level, name: "G1") }
  let(:other_level) { create(:level, name: "G2") }
  let(:player)      { create(:user, level: level) }

  it "inclut une annonce sans niveau (ouverte à tous)" do
    annonce = create(:annonce, :with_slot, user: create(:user))
    expect(described_class.call(user: player)).to include(annonce)
  end

  it "inclut une annonce dont le niveau correspond au joueur" do
    annonce = create(:annonce, :with_slot, user: create(:user), levels: [ level ])
    expect(described_class.call(user: player)).to include(annonce)
  end

  it "exclut une annonce d'un niveau non partagé" do
    annonce = create(:annonce, :with_slot, user: create(:user), levels: [ other_level ])
    expect(described_class.call(user: player)).not_to include(annonce)
  end

  it "exclut sa propre annonce" do
    annonce = create(:annonce, :with_slot, user: player)
    expect(described_class.call(user: player)).not_to include(annonce)
  end

  it "exclut une annonce dont tous les créneaux entrent en conflit avec l'agenda du joueur" do
    slot_start = (Time.current + 2.days).change(hour: 19, min: 0)
    annonce = create(:annonce, user: create(:user),
                     slots: [ build(:annonce_slot, start_at: slot_start, end_at: slot_start + 2.hours) ])

    # Le joueur est déjà inscrit à une session chevauchant l'unique créneau.
    create(:credit_transaction, user: player, amount: 10_000)
    conflicting = create(:session, :jeu_libre, start_at: slot_start, end_at: slot_start + 2.hours)
    create(:registration, user: player, session: conflicting)

    expect(described_class.call(user: player)).not_to include(annonce)
  end

  it "inclut une annonce si au moins un créneau reste libre" do
    free_start = (Time.current + 3.days).change(hour: 19, min: 0)
    busy_start = (Time.current + 4.days).change(hour: 19, min: 0)
    annonce = create(:annonce, user: create(:user), slots: [
      build(:annonce_slot, start_at: busy_start, end_at: busy_start + 2.hours),
      build(:annonce_slot, start_at: free_start, end_at: free_start + 2.hours)
    ])

    create(:credit_transaction, user: player, amount: 10_000)
    conflicting = create(:session, :jeu_libre, start_at: busy_start, end_at: busy_start + 2.hours)
    create(:registration, user: player, session: conflicting)

    expect(described_class.call(user: player)).to include(annonce)
  end

  it "n'inclut que les annonces ouvertes" do
    create(:annonce, :with_slot, :confirmed, user: create(:user))
    expect(described_class.call(user: player)).to be_empty
  end
end
