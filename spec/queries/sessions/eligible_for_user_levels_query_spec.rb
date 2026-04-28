require "rails_helper"

RSpec.describe Sessions::EligibleForUserLevelsQuery do
  describe ".call" do
    let(:coach) { create(:user, coach: true) }
    let(:allowed_level) { create(:level) }
    let(:other_level) { create(:level) }

    before do
      coach.balance.update!(amount: 10_000)
    end

    it "includes non-training sessions and matching training sessions" do
      training_with_matching_level = create(:session, :entrainement, user: coach, levels: [allowed_level], terrain: "Terrain 1")
      _training_with_other_level = create(:session, :entrainement, user: coach, levels: [other_level], terrain: "Terrain 2")
      training_without_levels = create(:session, :entrainement, user: coach, levels: [], terrain: "Terrain 3")
      free_play = create(:session, :jeu_libre, user: coach, terrain: "Terrain 1")

      result = described_class.call(relation: Session.all, level_ids: [allowed_level.id])

      expect(result).to include(training_with_matching_level, training_without_levels, free_play)
      expect(result).not_to include(_training_with_other_level)
    end
  end
end
