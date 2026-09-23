# frozen_string_literal: true

module Users
  # Crée le compte d'un visiteur qui achète un pack public sans être inscrit.
  # Le mot de passe est aléatoire : il reçoit un lien pour choisir le sien.
  class GuestSignup
    Result = Data.define(:user, :error)

    def initialize(email: nil, first_name: nil, last_name: nil)
      @email = email.to_s.strip.downcase
      @first_name = first_name
      @last_name = last_name
    end

    def call
      return Result.new(user: nil, error: "Cet email a déjà un compte. Connecte-toi pour acheter ce pack.") if User.exists?(email: @email)

      password = Devise.friendly_token.first(24)
      user = User.create!(email: @email, first_name: @first_name, last_name: @last_name,
                          password: password, password_confirmation: password)
      user.send_reset_password_instructions
      Result.new(user: user, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(user: nil, error: e.record.errors.full_messages.to_sentence)
    end
  end
end
