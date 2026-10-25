# frozen_string_literal: true

require "rails_helper"

RSpec.describe "UI kit", type: :request do
  let(:components) do
    Rails.root.glob("app/components/**/*_component.rb").map do |path|
      path.relative_path_from(Rails.root.join("app/components")).to_s.delete_suffix(".rb").camelize
    end - [ "ApplicationComponent" ]
  end

  it "est accessible sans connexion et hors moteurs de recherche" do
    get ui_kit_path

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
  end

  it "présente chaque composant de app/components" do
    get ui_kit_path

    rendered = Nokogiri::HTML(response.body).css("[data-ui-kit-component]").map { |node| node["data-ui-kit-component"] }
    expect(components - rendered).to be_empty, "Composants absents du UI kit : #{(components - rendered).join(', ')}"
  end

  it "n'écrit rien en base" do
    expect { get ui_kit_path }.not_to change { [ User.count, Session.count, Registration.count ] }
  end
end
