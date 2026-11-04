# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

RSpec.describe Ability, "Licence payée, dossier en attente" do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:user, activated_at: Time.current, dossier_complet: false) }
  let(:licence_pack) { create(:pack, pack_type: :licence, amount_cents: 5000) }
  let(:stage_pack) { create(:pack, pack_type: :stage, stage: create(:stage), amount_cents: 10_000) }
  let(:credits_pack) { create(:pack, pack_type: :credits, credits: 100, amount_cents: 1000) }

  it "garde l'accès restreint d'un membre sans licence" do
    expect(ability).not_to be_able_to(:read, Session)
    expect(ability).not_to be_able_to(:create, Registration)
    expect(ability).not_to be_able_to(:read, credits_pack)
    expect(ability).to be_able_to(:buy, stage_pack)
  end

  it "ne propose plus le pack licence déjà payé" do
    expect(ability).not_to be_able_to(:read, licence_pack)
    expect(ability).not_to be_able_to(:buy, licence_pack)
  end

  it "ouvre tout l'accès une fois le dossier complet" do
    user.update!(dossier_complet: true)

    expect(ability).to be_able_to(:read, Session)
    expect(ability).to be_able_to(:create, Registration)
    expect(ability).to be_able_to(:buy, licence_pack)
  end

  it "bloque aussi un coach sans dossier complet" do
    user.update!(coach: true)

    expect(Users::ActivationGate.restricted?(user)).to be(true)
  end
end
