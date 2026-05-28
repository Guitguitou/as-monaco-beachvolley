class ApplicationMailer < ActionMailer::Base
  CAPTIVE_LOGO_PATH = Rails.root.join("app/assets/images/Logo Captive Bleu Baseline.png").freeze
  CAPTIVE_LOGO_CID = "captive_logo.png"

  default from: "AS Monaco Beach Volley <asm.beachvolley@gmail.com>"
  layout "mailer"
  before_action :attach_captive_logo

  private

  def attach_captive_logo
    attachments.inline[CAPTIVE_LOGO_CID] = File.read(CAPTIVE_LOGO_PATH)
  end
end
