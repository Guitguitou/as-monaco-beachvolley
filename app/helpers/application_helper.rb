module ApplicationHelper
  def level_badge(level)
    content_tag :span, level.name,
    class: "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold text-white",
    style: "background-color: #{level.color};"
  end

  def get_session_type_label(session_type)
    Sessions::SessionType.for(session_type).label
  end

  def session_type_icon(session_type)
    Sessions::SessionType.for(session_type).icon
  end

  def get_session_type_classes(session_type)
    Sessions::SessionType.for(session_type).classes
  end

  # Serialized for Stimulus `session-form` (terrain options filtered by closure ranges).
  def terrain_closures_json_for_forms
    TerrainClosure.as_json_for_forms
  end

  # Whitelisted query params for linking back to sessions#index (grid or calendar, week, terrain).
  def sessions_index_return_params(source_params = nil)
    Sessions::ReturnParams.from(source_params || params)
  end

  # Session show URL from the calendar view with stable week anchor (for FullCalendar event.url fallback).
  def sessions_calendar_event_path(session_record)
    date = params[:date].presence || session_record.start_at.to_date.iso8601
    session_path(session_record, Sessions::ReturnParams.from(params).merge(view: "calendar", date: date))
  end

  def nav_link(name, path, icon:, extra_classes: nil)
    active = current_page?(path)

    base_classes = [
      "flex items-center gap-3 px-3 py-2 rounded-md",
      "hover:bg-gray-100 font-medium",
      "text-[14px] leading-5",            # 👈 taille uniforme
      (active ? "border-l-4 border-asmbv-red bg-asmbv-red-light text-asmbv-red font-semibold" : "text-gray-900")
    ]
    base_classes << extra_classes if extra_classes.present?

    link_to path, class: base_classes.join(" ") do
      concat lucide_icon(icon, class: "w-4 h-4 shrink-0 #{active ? 'text-asmbv-red' : 'text-gray-500'}") # 👈 icône uniforme
      concat content_tag(:span, name) # pas de classe spéciale -> hérite de text-[15px]/leading-5
    end
  end

  def nav_link_navbar(name, path, icon: nil)
    active = current_page?(path)
    # Pas d'opacité sur le texte : sur le rouge de marque, text-white/90 tombe à
    # 3.84:1, sous le minimum WCAG AA de 4.5:1. L'état actif est porté par le
    # filet du dessous, pas par un contraste dégradé.
    base_classes = [
      "inline-flex items-center gap-2 px-4 py-5 text-sm font-semibold tracking-wide border-b-2 transition-colors",
      (active ? "text-white border-white" : "text-white border-transparent hover:border-white/70 hover:bg-white/10")
    ]

    link_to path, class: base_classes.join(" ") do
      concat lucide_icon(icon, class: "w-4 h-4") if icon.present?
      concat content_tag(:span, name)
    end
  end

  CREDIT_TRANSACTION_TYPE_LABELS = {
    "purchase" => "Achat",
    "training_payment" => "Paiement d'entraînement",
    "free_play_payment" => "Paiement de jeu libre",
    "private_coaching_payment" => "Paiement de coaching privé",
    "refund" => "Remboursement",
    "manual_adjustment" => "Ajustement de l'admin"
  }.freeze

  def humanize_credit_transaction_type(transaction_type)
    CREDIT_TRANSACTION_TYPE_LABELS.fetch(transaction_type.to_s, "Transaction")
  end

  # Builds a sortable link for table headers, preserving current filters.
  # Usage: sortable_link_to("Nom", :name, preserve: { gender: params[:gender], ... })
  def sortable_link_to(title, key, preserve: {})
    current_sort = params[:sort].to_s
    current_direction = params[:direction] == "desc" ? "desc" : "asc"
    next_direction = (current_sort == key.to_s && current_direction == "asc") ? "desc" : "asc"

    url_params = preserve.merge(action: :index, sort: key, direction: next_direction, page: 1)

    link_to url_params, class: "inline-flex items-center gap-1 hover:text-asmbv-red" do
      concat content_tag(:span, title)
      if current_sort == key.to_s
        icon_name = current_direction == "asc" ? "chevron-up" : "chevron-down"
        concat lucide_icon(icon_name, size: 14, class: "text-gray-600")
      end
    end
  end

  # Titre de l'en-tête de page, ou nil si la page n'en déclare pas.
  #
  # Renvoyer nil est un cas normal : les pages Devise, les formulaires et les
  # écrans qui portent déjà leur propre titre n'affichent alors aucun en-tête.
  # (L'ancien repli "#{controller_name} #{action_name}" affichait « Sessions New »
  # en gros sur la page de connexion.)
  PAGE_TITLES = {
    "sessions#index" => "Calendrier",
    "packs#index" => "Boutique",
    "stages#index" => "Stages",
    "performances#index" => "Performances & stats",
    "annonces#index" => "Annonces de jeu libre",
    "profiles#show" => "Mon profil",
    "me/sessions#index" => "Mes sessions"
  }.freeze

  def default_page_title
    return content_for(:page_title) if content_for?(:page_title)

    PAGE_TITLES["#{controller_path}##{action_name}"]
  end

  # Helper to create external links that open in a new tab
  # Usage: external_link_to("Google", "https://google.com", class: "text-blue-500")
  def external_link_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options || {}
      options = name
      name = capture(&block)
    end

    # Ensure external links open in new tab with security attributes
    html_options ||= {}
    html_options[:target] = "_blank"
    html_options[:rel] = "noopener noreferrer"

    # Add external link icon if not already present
    unless html_options[:class]&.include?("no-external-icon")
      name = "#{name} #{lucide_icon('external-link', class: 'inline w-3 h-3 ml-1')}".html_safe
    end

    link_to(name, options, html_options)
  end

  # Helper to check if a URL is external
  def external_url?(url)
    return false if url.blank?

    begin
      uri = URI.parse(url)
      # Consider it external if it has a different host
      uri.host.present? && uri.host != request.host
    rescue URI::InvalidURIError
      false
    end
  end

  # Helper pour le composant Button
  def button(label, variant: :primary, size: :medium, href: nil, url: nil, icon: nil, **options)
    render ButtonComponent.new(
      variant: variant,
      size: size,
      href: href,
      url: url,
      icon: icon,
      **options
    ) do
      label
    end
  end

  # Helper pour le composant Tabs (barre d'onglets « underline »).
  # Voir TabsComponent pour la structure attendue de chaque onglet.
  def tab_bar(tabs, turbo_frame: nil)
    render TabsComponent.new(tabs: tabs, turbo_frame: turbo_frame)
  end

  # Get VAPID public key for push notifications
  def vapid_public_key
    ENV["VAPID_PUBLIC_KEY"] || Rails.application.credentials.dig(:vapid, :public_key) || ""
  end
end
