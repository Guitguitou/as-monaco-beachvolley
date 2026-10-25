# frozen_string_literal: true

require "rails_helper"

RSpec.describe DetailRowComponent, type: :component do
  it "affiche le libellé et la valeur, séparés par un filet" do
    render_inline(described_class.new(icon: "calendar-days", label: "Dates")) { "12/07 - 18/07" }

    expect(page).to have_css("div.border-b", text: "Dates")
    expect(page).to have_css("span", text: "12/07 - 18/07")
  end

  it "retire le filet sur la dernière ligne" do
    render_inline(described_class.new(icon: "users", label: "Coachs", last: true)) { "Marc" }

    expect(page).not_to have_css("div.border-b")
  end
end
