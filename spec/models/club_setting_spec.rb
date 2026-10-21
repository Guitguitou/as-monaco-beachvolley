# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClubSetting do
  it "renvoie toujours le même réglage du club" do
    expect(described_class.current).to eq(described_class.current)
    expect(described_class.count).to eq(1)
  end

  it "refuse un lien de formulaire qui n'est pas une URL web" do
    setting = described_class.current
    setting.membership_form_url = "pas un lien"
    expect(setting).not_to be_valid
  end
end
