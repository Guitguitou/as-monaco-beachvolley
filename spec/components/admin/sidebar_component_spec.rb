# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SidebarComponent, type: :component do
  let(:navigation) do
    Admin::Navigation.new(user: build(:user, :admin), routes: Rails.application.routes.url_helpers, alerts_count: 2)
  end

  it "ouvre la section de la page courante et marque son lien actif" do
    render_inline(described_class.new(navigation: navigation,
                                      location: Admin::CurrentLocation.new(path: "/admin/users/1", query: {})))

    expect(page).to have_css("details[open] summary", text: "Membres")
    expect(page).to have_no_css("details[open] summary", text: "Activité")
    expect(page).to have_css("a[aria-current='page']", text: "Joueurs")
    expect(page).to have_css("a", text: /Alertes\s*2/, visible: :all)
  end
end
