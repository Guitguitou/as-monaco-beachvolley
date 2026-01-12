# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:push_subscription) }

    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_presence_of(:p256dh) }
    it { is_expected.to validate_presence_of(:auth) }
    it { is_expected.to validate_uniqueness_of(:endpoint).scoped_to(:user_id) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:subscription1) { create(:push_subscription, user: user) }
    let!(:subscription2) { create(:push_subscription, user: user) }

    it "belongs to the correct user" do
      expect(user.push_subscriptions).to include(subscription1, subscription2)
    end
  end
end
