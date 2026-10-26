# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Navigation do
  let(:routes) { Rails.application.routes.url_helpers }

  def sections_for(user, alerts_count: 0)
    described_class.new(user: user, routes: routes, alerts_count: alerts_count).sections
  end

  it "montre toutes les sections à un admin" do
    titles = sections_for(build(:user, :admin)).map(&:title)

    expect(titles).to eq([ "Pilotage", "Activité", "Membres", "Finances", "Configuration" ])
  end

  it "limite le Responsable financier à Pilotage et Finances, sans la Boutique" do
    sections = sections_for(build(:user, :financial_manager))

    expect(sections.map(&:title)).to eq([ "Pilotage", "Finances" ])
    expect(sections.last.items.map(&:label)).to eq([ "Finances", "Historique achats" ])
  end

  it "porte le nombre d'alertes en badge, et rien quand il n'y en a pas" do
    alerts = ->(count) { sections_for(build(:user, :admin), alerts_count: count).first.items.last.badge }

    expect(alerts.call(3)).to eq(3)
    expect(alerts.call(0)).to be_nil
  end
end
