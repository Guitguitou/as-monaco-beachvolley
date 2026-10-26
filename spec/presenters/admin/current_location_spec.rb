# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CurrentLocation do
  let(:item) { ->(path) { Admin::Navigation::Item.new(label: "x", path: path, icon: "x") } }

  def location(path, query = {}) = described_class.new(path: path, query: query)

  it "active l'index sur ses pages de détail" do
    expect(location("/admin/users/3/edit").active?(item.call("/admin/users"))).to be(true)
    expect(location("/admin/users_export").active?(item.call("/admin/users"))).to be(false)
  end

  it "distingue le dashboard de son onglet Alertes" do
    dashboard = item.call("/admin")
    alerts = item.call("/admin?tab=alerts")

    expect(location("/admin", "tab" => "packs").active?(dashboard)).to be(true)
    expect(location("/admin", "tab" => "alerts").active?(dashboard)).to be(false)
    expect(location("/admin", "tab" => "alerts").active?(alerts)).to be(true)
    expect(location("/admin/users").active?(dashboard)).to be(false)
  end
end
