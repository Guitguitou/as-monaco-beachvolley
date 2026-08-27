# frozen_string_literal: true

# Affiche les messages flash sous forme de toasts ancrés en haut de l'écran.
#
# Rendu une seule fois par layout, au-dessus du contenu :
#
#   <%= render FlashComponent.new(flash: flash) %>
#
# Les messages de succès disparaissent seuls ; les erreurs restent affichées
# jusqu'à ce que l'utilisateur les ferme.
class FlashComponent < ApplicationComponent
  # Types de flash reconnus, mappés sur une apparence.
  # `notice` et `alert` sont ceux posés par Rails et Devise.
  KINDS = {
    "notice" => :success,
    "success" => :success,
    "alert" => :error,
    "error" => :error,
    "warning" => :warning,
    "info" => :info
  }.freeze

  # Délai avant disparition automatique, en millisecondes.
  # Les erreurs et avertissements ne disparaissent jamais seuls.
  AUTO_DISMISS_MS = 6000

  # Identifiant du conteneur, cible des `turbo_stream.replace`.
  DOM_ID = "flash"

  def initialize(flash:)
    @flash = flash
  end

  # Le conteneur est toujours rendu, même vide : sans lui dans le DOM, un
  # `turbo_stream.replace("flash", …)` n'aurait rien à remplacer et les
  # messages des réponses Turbo seraient perdus.
  private

  attr_reader :flash

  # [[kind, message], ...] — ignore les clés internes de Rails (`:timedout`…)
  # et les valeurs non textuelles.
  def messages
    @messages ||= flash.to_h.filter_map do |key, value|
      kind = KINDS[key.to_s]
      next if kind.nil?
      next if value.blank?

      [ kind, value.to_s ]
    end
  end

  def auto_dismiss?(kind)
    kind == :success || kind == :info
  end

  def wrapper_classes(kind)
    base = "pointer-events-auto w-full flex items-start gap-3 border-l-4 rounded-lg " \
           "px-4 py-3 shadow-lg transition duration-200 ease-out"
    "#{base} #{kind_classes(kind)}"
  end

  def kind_classes(kind)
    case kind
    when :success then "bg-white border-green-600 text-gray-900"
    when :error then "bg-white border-asmbv-red text-gray-900"
    when :warning then "bg-white border-orange-500 text-gray-900"
    else "bg-white border-blue-700 text-gray-900"
    end
  end

  def icon_name(kind)
    case kind
    when :success then "check-circle"
    when :error then "alert-circle"
    when :warning then "alert-triangle"
    else "info"
    end
  end

  def icon_classes(kind)
    base = "w-5 h-5 shrink-0 mt-0.5"
    color = case kind
    when :success then "text-green-600"
    when :error then "text-asmbv-red"
    when :warning then "text-orange-500"
    else "text-blue-700"
    end
    "#{base} #{color}"
  end

  # Les erreurs interrompent l'utilisateur, les succès se contentent de l'informer.
  def aria_role(kind)
    kind == :error ? "alert" : "status"
  end

  def aria_live(kind)
    kind == :error ? "assertive" : "polite"
  end
end
