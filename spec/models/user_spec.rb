# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    subject(:user) { create(:user) }

    it "has many user_levels" do
      expect(user).to respond_to(:user_levels)
      expect(user.user_levels).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many levels through user_levels" do
      expect(user).to respond_to(:levels)
      expect(user.levels).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has one balance" do
      expect(user).to respond_to(:balance)
      expect(user.balance).to be_a(Balance)
    end

    it "has many credit_transactions" do
      expect(user).to respond_to(:credit_transactions)
      expect(user.credit_transactions).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many credit_purchases" do
      expect(user).to respond_to(:credit_purchases)
      expect(user.credit_purchases).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many registrations" do
      expect(user).to respond_to(:registrations)
      expect(user.registrations).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many confirmed_registrations" do
      expect(user).to respond_to(:confirmed_registrations)
      expect(user.confirmed_registrations).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has many sessions_registered through confirmed_registrations" do
      expect(user).to respond_to(:sessions_registered)
      expect(user.sessions_registered).to be_a(ActiveRecord::Associations::CollectionProxy)
    end
  end

  describe "callbacks" do
    describe "after_create :init_balance" do
      it "creates a balance with amount 0" do
        user = create(:user)
        expect(user.balance).to be_present
        expect(user.balance.amount).to eq(0)
      end
    end

    describe "after_create :apply_legacy_level_assignment" do
      it "assigns level when provided via level= setter" do
        level = create(:level)
        user = User.create!(
          email: "test@example.com",
          password: "password123",
          first_name: "John",
          last_name: "Doe",
          level: level
        )

        expect(user.levels).to include(level)
        expect(user.level).to eq(level)
      end
    end
  end

  describe "scopes" do
    let!(:coach) { create(:user, coach: true, admin: false, responsable: false) }
    let!(:responsable) { create(:user, responsable: true, admin: false, coach: false) }
    let!(:admin) { create(:user, admin: true, coach: false, responsable: false) }
    let!(:regular_user) { create(:user, admin: false, coach: false, responsable: false) }

    describe ".coachs" do
      it "returns only users with coach role" do
        expect(described_class.coachs).to include(coach)
        expect(described_class.coachs).not_to include(regular_user, responsable, admin)
      end
    end

    describe ".responsables" do
      it "returns only users with responsable role" do
        expect(described_class.responsables).to include(responsable)
        expect(described_class.responsables).not_to include(regular_user, coach, admin)
      end
    end

    describe ".admins" do
      it "returns only users with admin role" do
        expect(described_class.admins).to include(admin)
        expect(described_class.admins).not_to include(regular_user, coach, responsable)
      end
    end

    describe ".with_enough_credits" do
      let(:session) { create(:session, price: 400) }
      let!(:rich_user) { create(:user) }
      let!(:poor_user) { create(:user) }

      before do
        rich_user.balance.update!(amount: 500)
        poor_user.balance.update!(amount: 100)
      end

      it "returns only users with balance >= session price" do
        result = described_class.with_enough_credits(session)

        expect(result).to include(rich_user)
        expect(result).not_to include(poor_user)
      end
    end

    describe ".activated" do
      let!(:activated_user) { create(:user, activated_at: Time.current) }
      let!(:not_activated_user) { create(:user, activated_at: nil) }

      it "returns only users with activated_at set" do
        expect(described_class.activated).to include(activated_user)
        expect(described_class.activated).not_to include(not_activated_user)
      end
    end

    describe ".not_activated" do
      let!(:activated_user) { create(:user, activated_at: Time.current) }
      let!(:not_activated_user) { create(:user, activated_at: nil) }

      it "returns only users without activated_at" do
        expect(described_class.not_activated).to include(not_activated_user)
        expect(described_class.not_activated).not_to include(activated_user)
      end
    end
  end

  describe "#activated?" do
    context "when activated_at is present" do
      subject(:user) { create(:user, activated_at: Time.current) }

      it { is_expected.to be_activated }
    end

    context "when activated_at is nil" do
      subject(:user) { create(:user, activated_at: nil) }

      it { is_expected.not_to be_activated }
    end
  end

  describe "#activate!" do
    subject(:user) { create(:user, activated_at: nil) }

    it "sets activated_at to current time" do
      expect { user.activate! }.to change { user.reload.activated_at }.from(nil)
      expect(user).to be_activated
    end

    context "when already activated" do
      let(:original_time) { 1.day.ago }

      before { user.update!(activated_at: original_time) }

      it "does not update activated_at" do
        user.activate!
        expect(user.reload.activated_at).to be_within(1.second).of(original_time)
      end
    end
  end

  describe "#active_for_authentication?" do
    context "when user is not disabled and activated" do
      subject(:user) { create(:user, disabled_at: nil, activated_at: Time.current) }

      it { is_expected.to be_active_for_authentication }
    end

    context "when user is disabled" do
      subject(:user) { create(:user, disabled_at: Time.current, activated_at: Time.current) }

      it { is_expected.not_to be_active_for_authentication }
    end

    context "when user is not activated" do
      subject(:user) { create(:user, disabled_at: nil, activated_at: nil) }

      it "allows login with limited access" do
        expect(user).to be_active_for_authentication
      end
    end
  end

  describe "#inactive_message" do
    context "when user is disabled" do
      subject(:user) { create(:user, disabled_at: Time.current) }

      it "returns :locked" do
        expect(user.inactive_message).to eq(:locked)
      end
    end

    context "when user is not disabled" do
      subject(:user) { create(:user, disabled_at: nil) }

      it "returns default devise message" do
        expect(user.inactive_message).to be_in([ :inactive, nil ])
      end
    end
  end

  describe "#full_name" do
    subject(:user) { create(:user, first_name: "John", last_name: "Doe") }

    it "returns first and last name concatenated" do
      expect(user.full_name).to eq("John Doe")
    end
  end

  describe "#credit_balance" do
    subject(:user) { create(:user) }

    context "when balance exists" do
      before { user.balance.update!(amount: 100) }

      it "returns balance amount" do
        expect(user.credit_balance).to eq(100)
      end
    end

    context "when balance is nil" do
      before { user.balance.destroy }

      it "returns 0" do
        expect(user.credit_balance).to eq(0)
      end
    end

    context "when credit transactions exist" do
      before do
        create(:credit_transaction, user: user, amount: 100)
        create(:credit_transaction, user: user, amount: -50)
      end

      it "reflects the sum of transactions" do
        expect(user.reload.credit_balance).to eq(50)
      end
    end
  end

  describe "#level" do
    let(:level1) { create(:level) }
    let(:level2) { create(:level) }
    subject(:user) { create(:user) }

    context "when user has levels" do
      before { user.levels << [ level1, level2 ] }

      it "returns the first level" do
        expect(user.level).to eq(level1)
      end
    end

    context "when user has no levels" do
      it "returns nil" do
        expect(user.level).to be_nil
      end
    end
  end

  describe "#level=" do
    let(:level) { create(:level) }

    it "assigns level for legacy compatibility" do
      user = User.new(
        email: "legacy@example.com",
        password: "password123",
        first_name: "Legacy",
        last_name: "User"
      )
      user.level = level
      user.save!

      expect(user.reload.levels).to include(level)
    end
  end

  describe "#salary_per_training" do
    subject(:user) { create(:user, salary_per_training_cents: 2500) }

    it "converts cents to euros" do
      expect(user.salary_per_training).to eq(25.0)
    end

    context "when salary_per_training_cents is 0" do
      before { user.update!(salary_per_training_cents: 0) }

      it "returns 0.0" do
        expect(user.salary_per_training).to eq(0.0)
      end
    end
  end

  describe "#salary_per_training=" do
    subject(:user) { create(:user) }

    it "converts euros to cents and stores" do
      user.salary_per_training = 35.50
      expect(user.salary_per_training_cents).to eq(3550)
    end

    it "rounds to nearest cent" do
      user.salary_per_training = 35.556
      expect(user.salary_per_training_cents).to eq(3556)
    end

    it "handles zero" do
      user.salary_per_training = 0
      expect(user.salary_per_training_cents).to eq(0)
    end
  end
end
