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

  # Apparence de chaque type : bordure du toast, icône et couleur de l'icône.
  STYLES = {
    success: { border: "border-green-600", icon: "check-circle", text: "text-green-600" },
    error: { border: "border-asmbv-red", icon: "alert-circle", text: "text-asmbv-red" },
    warning: { border: "border-orange-500", icon: "alert-triangle", text: "text-orange-500" },
    info: { border: "border-blue-700", icon: "info", text: "text-blue-700" }
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
    base = "pointer-events-auto w-full flex items-start gap-3 border-l-4 rounded-none " \
           "px-4 py-3 shadow-lg transition duration-200 ease-out"
    "#{base} #{kind_classes(kind)}"
  end

  def kind_classes(kind)
    "bg-white #{style(kind)[:border]} text-gray-900"
  end

  def icon_name(kind)
    style(kind)[:icon]
  end

  def icon_classes(kind)
    "w-5 h-5 shrink-0 mt-0.5 #{style(kind)[:text]}"
  end

  def style(kind)
    STYLES.fetch(kind, STYLES[:info])
  end

  # Les erreurs interrompent l'utilisateur, les succès se contentent de l'informer.
  def aria_role(kind)
    kind == :error ? "alert" : "status"
  end

  def aria_live(kind)
    kind == :error ? "assertive" : "polite"
  end
end
