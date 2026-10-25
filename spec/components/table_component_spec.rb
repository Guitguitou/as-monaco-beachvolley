# frozen_string_literal: true

require "rails_helper"

RSpec.describe TableComponent, type: :component do
  def render_table(framed: false, rows: [ "Janvier" ])
    render_inline(described_class.new(framed: framed)) do |table|
      table.with_column("Mois")
      table.with_column("Total", align: :right)
      rows.each do |name|
        table.with_row(id: "row_#{name}", data: { month: name }) do |row|
          row.with_cell(weight: :medium) { name }
          row.with_cell(align: :right) { "10 €" }
        end
      end
      table.with_empty(icon: "calendar-x", message: "Aucun mois")
    end
  end

  it "rend les en-têtes et les cellules" do
    render_table

    expect(page).to have_css("th[scope=col]", text: "Mois")
    expect(page).to have_css("th.text-right", text: "Total")
    expect(page).to have_css("td.font-medium.whitespace-nowrap", text: "Janvier")
  end

  it "garde les attributs HTML des lignes" do
    render_table

    expect(page).to have_css("tr#row_Janvier[data-month='Janvier'].hover\\:bg-gray-50")
  end

  it "n'affiche la ligne vide que sans lignes, sur toute la largeur" do
    render_table
    expect(page).not_to have_text("Aucun mois")

    render_table(rows: [])
    expect(page).to have_css("td[colspan='2']", text: "Aucun mois")
  end

  it "encadre le tableau seulement si demandé" do
    render_table(framed: true)
    expect(page).to have_css("div.border.shadow-sm > table")

    render_table
    expect(page).not_to have_css("div.shadow-sm")
  end
end
