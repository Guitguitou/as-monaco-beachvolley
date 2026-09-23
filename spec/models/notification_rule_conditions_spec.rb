# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationRule, "conditions" do
  def matches?(conditions, context)
    build(:notification_rule, conditions: conditions).matches?(context)
  end

  it "compares numbers" do
    expect(matches?({ "credits" => { "lt" => 10 } }, { credits: 5 })).to be(true)
    expect(matches?({ "credits" => { "lte" => 5 } }, { credits: 5 })).to be(true)
    expect(matches?({ "credits" => { "gt" => 10 } }, { credits: 5 })).to be(false)
    expect(matches?({ "credits" => { "gte" => 5, "lt" => 6 } }, { credits: 5 })).to be(true)
  end

  it "checks membership" do
    expect(matches?({ "type" => { "in" => %w[jeu_libre stage] } }, { type: "stage" })).to be(true)
    expect(matches?({ "type" => { "not_in" => %w[jeu_libre stage] } }, { type: "stage" })).to be(false)
  end

  it "falls back to equality" do
    expect(matches?({ "type" => { "eq" => "stage" } }, { type: "stage" })).to be(true)
    expect(matches?({ "type" => "stage" }, { "type" => "tournoi" })).to be(false)
  end
end
