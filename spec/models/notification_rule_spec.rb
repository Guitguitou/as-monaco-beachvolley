# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationRule, type: :model do
  describe "validations" do
    subject { build(:notification_rule) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:title_template) }
    it { is_expected.to validate_presence_of(:body_template) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(NotificationRule::EVENT_TYPES) }
  end

  describe "scopes" do
    let!(:enabled_rule) { create(:notification_rule, enabled: true) }
    let!(:disabled_rule) { create(:notification_rule, enabled: false) }
    let!(:session_rule) { create(:notification_rule, event_type: "session_created") }
    let!(:registration_rule) { create(:notification_rule, event_type: "registration_confirmed") }

    describe ".enabled" do
      it "returns only enabled rules" do
        expect(described_class.enabled).to include(enabled_rule)
        expect(described_class.enabled).not_to include(disabled_rule)
      end
    end

    describe ".for_event" do
      it "returns only rules for the specified event" do
        expect(described_class.for_event("session_created")).to include(session_rule)
        expect(described_class.for_event("session_created")).not_to include(registration_rule)
      end
    end
  end

  describe "#matches?" do
    let(:rule) { create(:notification_rule, conditions: {}) }

    context "when rule has no conditions" do
      it "always matches" do
        expect(rule.matches?({})).to be true
        expect(rule.matches?({ user: "test" })).to be true
      end
    end

    context "when rule has conditions" do
      let(:rule) { create(:notification_rule, conditions: { "user_level" => "advanced" }) }

      it "matches when context matches conditions" do
        expect(rule.matches?({ "user_level" => "advanced" })).to be true
        expect(rule.matches?({ user_level: "advanced" })).to be true
      end

      it "does not match when context does not match" do
        expect(rule.matches?({ "user_level" => "beginner" })).to be false
      end
    end

    context "when rule is disabled" do
      let(:rule) { create(:notification_rule, enabled: false) }

      it "never matches" do
        expect(rule.matches?({})).to be false
      end
    end
  end

  describe "#render_title and #render_body" do
    let(:rule) do
      create(:notification_rule,
             title_template: "Session: {{session_name}}",
             body_template: "Date: {{session_date}}")
    end

    it "renders templates with context variables" do
      context = { session_name: "Training", session_date: "01/01/2024" }
      expect(rule.render_title(context)).to eq("Session: Training")
      expect(rule.render_body(context)).to eq("Date: 01/01/2024")
    end

    it "handles missing variables gracefully" do
      context = { session_name: "Training" }
      expect(rule.render_title(context)).to eq("Session: Training")
      expect(rule.render_body(context)).to eq("Date: ")
    end
  end
end
