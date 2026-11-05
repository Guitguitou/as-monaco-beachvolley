# frozen_string_literal: true

# Carte d'état de la licence.
#
# La licence ne figurait nulle part côté joueur, alors que /profile est l'une
# des rares pages autorisées aux comptes non activés : un joueur sans licence y
# arrivait sans explication ni moyen d'agir. Elle conditionne aussi la fenêtre
# de priorité de 24 h à l'inscription (Sessions::RegistrationPolicy), ce que
# rien n'indiquait.
#
# Les libellés de `license_type` reprennent ceux du formulaire admin
# (app/views/admin/users/_form.html.erb) pour que joueur et admin lisent la
# même chose.
class LicenseCardComponent < ApplicationComponent
  LICENSE_TYPE_LABELS = {
    "libre" => "Libre",
    "competition" => "Compétition"
  }.freeze

  def initialize(user:)
    @user = user
  end

  private

  attr_reader :user

  def licence_payee?
    user.licence_payee?
  end

  def dossier_en_attente?
    user.dossier_en_attente?
  end

  def license_type_label
    LICENSE_TYPE_LABELS[user.license_type.to_s.presence]
  end

  def competition?
    user.license_type.to_s == "competition"
  end

  def renewed?
    user.next_season_renewed?
  end

  def activated_on
    return nil if user.activated_at.blank?

    l(user.activated_at.to_date, format: :long)
  end

  def title
    return "Licence à régler" unless licence_payee?

    dossier_en_attente? ? "Licence reçue" : "Licence active"
  end

  def description
    if !licence_payee?
      "Ta licence n'est pas encore enregistrée. Ton compte sera actif quand elle sera réglée et ton dossier validé."
    elsif dossier_en_attente?
      "Licence reçue, dossier en attente de validation par le Staff. Ton compte sera actif dès qu'il sera validé."
    elsif competition?
      "Ta licence compétition t'ouvre les inscriptions 24 h avant les autres joueurs."
    else
      "Tu peux t'inscrire à toutes les sessions ouvertes."
    end
  end

  def wrapper_classes
    base = "border rounded-none p-5 sm:p-6"
    user.compte_actif? ? "#{base} border-gray-200 bg-white" : "#{base} border-brand bg-brand-light"
  end

  def icon_name
    user.compte_actif? ? "shield-check" : "shield-alert"
  end

  def icon_classes
    "w-6 h-6 shrink-0 text-brand"
  end
end
