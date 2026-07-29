require "rails_helper"

RSpec.describe Licenses::ResetSeason do
  describe ".call" do
    it "deactivates an activated user without renewal" do
      user = create(:user, activated_at: 1.year.ago, next_season_renewed: false)

      result = described_class.call

      expect(user.reload.activated?).to be(false)
      expect(result.deactivated).to eq(1)
      expect(result.kept).to eq(0)
    end

    it "keeps a renewed user and consumes the renewal flag" do
      user = create(:user, activated_at: 1.year.ago, next_season_renewed: true)

      result = described_class.call

      expect(user.reload.activated?).to be(true)
      expect(user.next_season_renewed?).to be(false)
      expect(result.kept).to eq(1)
      expect(result.deactivated).to eq(0)
    end

    it "ignores non-activated users" do
      user = create(:user, activated_at: nil, next_season_renewed: false)

      described_class.call

      expect(user.reload.activated?).to be(false)
    end

    it "returns the counts of kept and deactivated licences" do
      create(:user, activated_at: 1.year.ago, next_season_renewed: true)
      create(:user, activated_at: 1.year.ago, next_season_renewed: false)
      create(:user, activated_at: 1.year.ago, next_season_renewed: false)

      result = described_class.call

      expect(result.kept).to eq(1)
      expect(result.deactivated).to eq(2)
    end

    it "consumes the renewal flag so a later season reset deactivates a non-renewed member" do
      # La coche est à usage unique : après un premier reset, le membre conservé
      # est actif pour la nouvelle saison mais n'a pas encore payé la suivante.
      # Un second reset (saison d'après) le désactive donc, ce qui est attendu.
      user = create(:user, activated_at: 1.year.ago, next_season_renewed: true)

      described_class.call
      expect(user.reload.activated?).to be(true)

      described_class.call
      expect(user.reload.activated?).to be(false)
    end
  end
end
