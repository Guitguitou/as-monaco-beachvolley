require "rails_helper"

RSpec.describe Admin::FinancesTabComponent, type: :component do
  let(:revenues) { { week: 1000.0, month: 4000.0, year: 10_000.0 } }
  let(:coach_salaries) { { week: 1200.0, month: 2500.0, year: 8000.0 } }
  let(:breakdowns) do
    {
      sessions: { "entrainement" => 3000.0, "jeu_libre" => 1000.0 },
      packs: { "credits" => 7000.0 }
    }
  end

  it "renders financial cards and negative weekly profit" do
    render_inline(described_class.new(revenues: revenues, coach_salaries: coach_salaries, breakdowns: breakdowns))

    expect(page).to have_text("Chiffre d'Affaires")
    expect(page).to have_text("Salaires Coachs")
    expect(page).to have_text("Bénéfice Semaine")
    expect(page).to have_css(".text-red-600")
  end
end
