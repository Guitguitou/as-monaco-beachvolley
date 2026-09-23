# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CardAction do
  def action(**state)
    defaults = { signed_in: true, registered: false, waitlisted: false, full: false, open: true,
                 closed_reason: "Les inscriptions ouvrent lundi.", conflict: false, not_enough_credits: false }
    described_class.new(**defaults.merge(state))
  end

  it "offers to register, or to join the waitlist when full" do
    expect([ action.name, action.label ]).to eq([ :register, "Je m'inscris" ])
    expect([ action(full: true).name, action(full: true).label ]).to eq([ :waitlist, "Rejoindre la liste d'attente" ])
  end

  it "offers to leave for a player already in" do
    expect(action(registered: true).name).to eq(:unregister)
    expect(action(waitlisted: true).label).to eq("Quitter la liste d'attente")
    expect(action(registered: true).destructive?).to be(true)
  end

  it "explains the first obstacle" do
    expect(action(signed_in: false).label).to eq("Connecte-toi pour t'inscrire")
    expect(action(open: false).label).to eq("Les inscriptions ouvrent lundi.")
    expect(action(conflict: true).label).to eq("Déjà une session sur ce créneau")
    expect(action(not_enough_credits: true).label).to eq("Crédits insuffisants")
    expect([ action(conflict: true).name, action(conflict: true).actionable? ]).to eq([ :blocked, false ])
  end
end
