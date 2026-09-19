# frozen_string_literal: true

module Sherlock
  # Traduit les champs d'une réponse Sherlock's en issue de paiement.
  #
  # `responseCode` fait autorité : il est toujours présent dans la réponse et
  # documenté code par code. `transactionStatus`, dont la présence dépend du
  # contrat, ne sert que de repli.
  #
  # Toute valeur inconnue vaut un échec. C'est volontaire : un achat ne doit
  # jamais rester bloqué en `pending` faute de savoir interpréter sa réponse.
  class Outcome
    ACCEPTED_CODE = "00"
    CUSTOMER_CANCELLATION_CODE = "17"

    # Libellés officiels des responseCode Sherlock's, pour qu'un refus soit
    # exploitable au support sans aller relire la doc LCL.
    CODE_LABELS = {
      "00" => "Paiement accepté",
      "02" => "Autorisation à demander par téléphone à la banque",
      "03" => "Contrat commerçant invalide",
      "05" => "Autorisation refusée",
      "11" => "Carte sur liste grise",
      "12" => "Transaction invalide",
      "14" => "Numéro de carte invalide",
      "17" => "Paiement annulé par le client",
      "24" => "Opération impossible",
      "25" => "Transaction inconnue",
      "30" => "Format de la requête invalide",
      "34" => "Suspicion de fraude",
      "40" => "Fonction non supportée",
      "51" => "Montant trop élevé",
      "54" => "Date de validité de la carte dépassée",
      "55" => "Code confidentiel erroné",
      "56" => "Carte absente du fichier",
      "57" => "Transaction non permise au porteur",
      "58" => "Transaction interdite au terminal",
      "59" => "Suspicion de fraude",
      "60" => "La banque doit être contactée",
      "63" => "Règles de sécurité non respectées",
      "68" => "Réponse reçue trop tard",
      "75" => "Nombre de tentatives de saisie dépassé",
      "90" => "Arrêt momentané du système",
      "94" => "Transaction dupliquée",
      "97" => "Session de paiement expirée",
      "99" => "Incident technique de la banque"
    }.freeze

    # Statuts textuels rencontrés selon le contrat et la passerelle simulée.
    # Sherlock's écrit AUTHORISED (orthographe britannique) là où d'autres
    # passerelles écrivent AUTHORIZED : les deux sont acceptés.
    STATUSES = {
      "authorised" => :paid,
      "authorized" => :paid,
      "to_capture" => :paid,
      "captured" => :paid,
      "success" => :paid,
      "paid" => :paid,
      "abandoned" => :cancelled,
      "cancel" => :cancelled,
      "canceled" => :cancelled,
      "cancelled" => :cancelled
    }.freeze

    def initialize(fields)
      @fields = fields.to_h.with_indifferent_access
    end

    def to_sym
      return outcome_for_code if code.present?

      STATUSES.fetch(status, :failed)
    end

    def paid?
      to_sym == :paid
    end

    def cancelled?
      to_sym == :cancelled
    end

    def failed?
      to_sym == :failed
    end

    # Motif lisible, stocké sur l'achat et affiché au client en cas de refus.
    def reason
      return CODE_LABELS[code] if CODE_LABELS.key?(code)
      return "Paiement refusé (code #{code})" if code.present?

      explicit_message || fallback_message
    end

    private

    attr_reader :fields

    def outcome_for_code
      case code
      when ACCEPTED_CODE then :paid
      when CUSTOMER_CANCELLATION_CODE then :cancelled
      else :failed
      end
    end

    def code
      @code ||= fields[:responseCode].to_s.strip
    end

    def status
      @status ||= (fields[:transactionStatus].presence || fields[:status]).to_s.strip.downcase
    end

    def explicit_message
      fields[:errorMessage].presence || fields[:responseMessage].presence
    end

    def fallback_message
      status.present? ? "Paiement refusé (statut #{status})" : "Paiement refusé sans motif transmis"
    end
  end
end
