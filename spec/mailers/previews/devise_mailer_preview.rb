# frozen_string_literal: true

# Previews des mails Devise (utiles pour vérifier que le footer Captive
# s'applique bien aussi à ces mails, via parent_mailer = ApplicationMailer).
# Accessibles sur http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(preview_user, "fake-preview-token")
  end

  def password_change
    Devise::Mailer.password_change(preview_user)
  end

  def email_changed
    Devise::Mailer.email_changed(preview_user)
  end

  private

  def preview_user
    User.first || begin
      user = User.new(
        first_name: "Charlie",
        last_name: "Preview",
        email: "preview@example.com"
      )
      user.id = 1
      user
    end
  end
end
