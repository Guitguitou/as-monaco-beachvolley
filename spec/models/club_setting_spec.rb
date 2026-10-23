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

  it "porte les règles de Monaco par défaut" do
    expect(described_class.current.price_by_type).to eq(ClubRules::DEFAULT_PRICE_BY_TYPE)
  end

  describe "validations des règles" do
    subject(:setting) { described_class.current }

    {
      entrainement_price_cents: [ -1, 1.5 ],
      registration_deadline_hour: [ -1, 24 ],
      cancellation_deadline_hour: [ -1, 24 ],
      priority_window_hours: [ -1, 73 ],
      cancellation_hours_before: [ -1, 73 ],
      registration_opening_days: [ 0, 31 ],
      cancellation_deadline_mode: [ "midi", nil ]
    }.each do |attribute, invalid_values|
      invalid_values.each do |value|
        it "refuse #{attribute} = #{value.inspect}" do
          setting.public_send(:"#{attribute}=", value)
          expect(setting).not_to be_valid
          expect(setting.errors[attribute]).to be_present
        end
      end
    end

    it "accepte les bornes" do
      setting.assign_attributes(stage_price_cents: 0, registration_deadline_hour: 23, priority_window_hours: 72,
                                registration_opening_days: 30, cancellation_deadline_mode: "hours_before",
                                cancellation_hours_before: 0)
      expect(setting).to be_valid
    end
  end
end
