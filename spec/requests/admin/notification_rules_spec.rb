require "rails_helper"

RSpec.describe "Admin::NotificationRules", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:rule) { create(:notification_rule, name: "Rule One") }

  before { host! "localhost" }
  before { allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token) }

  describe "authorization" do
    it "redirects guest users" do
      get admin_notification_rules_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      login_as regular_user, scope: :user
      get admin_notification_rules_path

      expect(response).to have_http_status(:found)
    end
  end

  context "when admin is signed in" do
    before { login_as admin, scope: :user }

    it "lists existing rules" do
      get admin_notification_rules_path

      expect(response).to have_http_status(:not_acceptable)
    end

    it "creates a notification rule" do
      expect do
        post admin_notification_rules_path, params: {
          notification_rule: {
            name: "Rule Two",
            event_type: "session_cancelled",
            title_template: "Titre",
            body_template: "Corps",
            enabled: "1",
            conditions: { "user_level" => "advanced" }
          }
        }
      end.to change(NotificationRule, :count).by(1)

      created = NotificationRule.order(:created_at).last
      expect(response).to redirect_to(admin_notification_rules_path)
      expect(created.name).to eq("Rule Two")
      expect(created.conditions).to eq({ "user_level" => "advanced" })
    end

    it "updates a notification rule" do
      patch admin_notification_rule_path(rule), params: {
        notification_rule: {
          name: "Rule Updated",
          enabled: false
        }
      }

      expect(response).to redirect_to(admin_notification_rules_path)
      expect(rule.reload.name).to eq("Rule Updated")
      expect(rule.enabled).to be(false)
    end

    it "deletes a notification rule" do
      expect do
        delete admin_notification_rule_path(rule)
      end.to change(NotificationRule, :count).by(-1)

      expect(response).to redirect_to(admin_notification_rules_path)
    end
  end
end
