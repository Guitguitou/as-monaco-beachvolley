# frozen_string_literal: true

require "rails_helper"

RSpec.describe CardComponent, type: :component do
  it "renders a padded card, as a link when given a target" do
    render_inline(described_class.new(href: "/sessions/1", padding: :lg, accent: :free_play, class_name: "mt-2")) { "Contenu" }

    expect(page).to have_css("a.p-6.border-t-blue-700.mt-2[href='/sessions/1']", text: "Contenu")
  end

  it "falls back to the medium padding and no accent" do
    render_inline(described_class.new(padding: :huge, accent: :unknown)) { "Contenu" }

    expect(page).to have_css("div.p-5")
    expect(page).not_to have_css("[class*='border-t-4']")
  end

  it "can drop the padding" do
    render_inline(described_class.new(padding: :none)) { "Contenu" }

    expect(page).not_to have_css("[class*='p-']")
  end
end
