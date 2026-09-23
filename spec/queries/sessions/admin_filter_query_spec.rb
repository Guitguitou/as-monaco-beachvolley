require "rails_helper"

RSpec.describe Sessions::AdminFilterQuery do
  describe ".call" do
    let(:coach) { create(:user, coach: true) }
    let(:other_coach) { create(:user, coach: true) }

    def build_session(trait = nil, **attrs)
      attrs = { user: coach, start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour }.merge(attrs)
      trait ? create(:session, trait, **attrs) : create(:session, **attrs)
    end

    it "compte par type avant d'appliquer le filtre de type" do
      build_session(start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour)
      build_session(start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
      build_session(:tournoi, start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour)

      result = described_class.call(relation: Session.all, params: { session_type: "tournoi" })

      expect(result.type_counts).to eq("entrainement" => 2, "tournoi" => 1)
      expect(result.total_count).to eq(3)
      expect(result.current_type).to eq("tournoi")
      expect(result.filtered_count).to eq(1)
      expect(result.relation.pluck(:session_type)).to eq([ "tournoi" ])
    end

    it "ignore un type invalide" do
      build_session

      result = described_class.call(relation: Session.all, params: { session_type: "n_importe_quoi" })

      expect(result.current_type).to be_nil
      expect(result.relation.count).to eq(1)
    end

    it "filtre par coach" do
      mine = build_session
      _theirs = build_session(user: other_coach, start_at: 5.days.from_now, end_at: 5.days.from_now + 1.hour)

      result = described_class.call(relation: Session.all, params: { coach_id: coach.id })

      expect(result.relation).to contain_exactly(mine)
    end

    it "ordonne par start_at décroissant" do
      old = build_session(start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour)
      recent = build_session(start_at: 4.days.from_now, end_at: 4.days.from_now + 1.hour)

      result = described_class.call(relation: Session.all, params: {})

      expect(result.relation.to_a).to eq([ recent, old ])
    end

    it "filtre par dates, avec une seule borne ou les deux" do
      soon = build_session(start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour)
      later = build_session(start_at: 10.days.from_now, end_at: 10.days.from_now + 1.hour)
      cut = 5.days.from_now.iso8601

      filter = ->(params) { described_class.call(relation: Session.all, params: params).relation.to_a }

      expect(filter.call(start_at_from: cut)).to eq([ later ])
      expect(filter.call(start_at_to: cut)).to eq([ soon ])
      expect(filter.call(start_at_from: 2.days.ago.iso8601, start_at_to: cut)).to eq([ soon ])
      expect(filter.call(start_at_from: "pas une date")).to eq([ later, soon ])
    end

    it "filtre sur la période en cours" do
      this_month = build_session(start_at: Time.zone.now.end_of_month - 2.hours, end_at: Time.zone.now.end_of_month - 1.hour)
      build_session(start_at: 40.days.from_now, end_at: 40.days.from_now + 1.hour)

      expect(described_class.call(relation: Session.all, params: { period: "month" }).relation.to_a).to eq([ this_month ])
      expect(described_class.call(relation: Session.all, params: { period: "decade" }).relation.count).to eq(2)
    end
  end
end
