# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::ActivationGate do
  describe ".restricted?" do
    it "restricts a member who has not been activated yet" do
      expect(described_class.restricted?(build(:user, activated_at: nil))).to be(true)
      expect(described_class.restricted?(build(:user, activated_at: Time.current))).to be(false)
    end

    it "never restricts admins and financial managers" do
      expect(described_class.restricted?(build(:user, :admin, activated_at: nil))).to be(false)
      expect(described_class.restricted?(build(:user, :financial_manager, activated_at: nil))).to be(false)
    end
  end

  describe ".allows?" do
    it "opens the pages needed to get a licence or a pack" do
      expect(described_class.allows?("/packs")).to be(true)
      expect(described_class.allows?("/packs/12/buy")).to be(true)
      expect(described_class.allows?("/checkout/42")).to be(true)
      expect(described_class.allows?("/stages/3")).to be(true)
      expect(described_class.allows?(Rails.application.routes.url_helpers.infos_brochure_path)).to be(true)
    end

    it "closes the rest of the app" do
      expect(described_class.allows?("/sessions")).to be(false)
      expect(described_class.allows?("/me/sessions")).to be(false)
    end
  end
end
