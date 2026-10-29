# frozen_string_literal: true

# E-mails de la boutique équipements (cf. GLOSSARY.md).
class ShopMailer < ApplicationMailer
  def unfinished_order(order)
    @order = order
    @user = order.user
    mail(to: @user.email, subject: "Ta commande d'équipements n'est pas encore payée")
  end
end
