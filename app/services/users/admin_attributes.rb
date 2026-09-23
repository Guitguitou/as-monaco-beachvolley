# frozen_string_literal: true

module Users
  # Applique le formulaire admin d'un membre. Un mot de passe laissé vide ne
  # change rien, sauf à la création où il est tiré au hasard ; la case
  # « activer » active ou désactive le compte.
  module AdminAttributes
    def self.apply(user, attributes, activate:)
      attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
      user.assign_attributes(attributes)
      user.password = SecureRandom.hex(8) if user.new_record? && user.password.blank?
      case activate
      when "1" then user.activated_at ||= Time.current
      when "0" then user.activated_at = nil
      end
      user
    end
  end
end
