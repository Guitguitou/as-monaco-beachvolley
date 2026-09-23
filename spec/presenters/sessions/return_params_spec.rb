# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ReturnParams do
  it "keeps the calendar navigation state and drops the blank or unknown values" do
    params = ActionController::Parameters.new(view: "grid", date: "2026-09-21", for_me: "true", terrain: "Terrain 2", page: "3")

    expect(described_class.from(params)).to eq({ view: "grid", date: "2026-09-21", for_me: "1", terrain: "Terrain 2" })
  end

  it "drops what is missing or invalid" do
    params = ActionController::Parameters.new(view: "list", date: "", for_me: "0")

    expect(described_class.from(params)).to eq({})
  end
end
