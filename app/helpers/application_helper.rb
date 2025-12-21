# frozen_string_literal: true

module ApplicationHelper
  def level_badge(level)
    content_tag :span, level.name,
    class: "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold text-white",
    style: "background-color: #{level.color};"
  end

  def get_session_type_label(session_type)
    labels = {
      "entrainement" => "Entraînement",
      "jeu_libre" => "Jeu libre",
      "tournoi" => "Tournoi",
      "coaching_prive" => "Coaching privé"
    }
    labels[session_type] || session_type.humanize
  end

  def session_type_icon(session_type)
    icons = {
      "entrainement" => "dumbbell",
      "jeu_libre" => "volleyball",
      "tournoi" => "trophy",
      "coaching_prive" => "shield-user"
    }
    icons[session_type] || "volleyball"
  end

  def get_session_type_classes(session_type)
    classes = {
      "entrainement" => "bg-green-100 text-green-800",
      "jeu_libre" => "bg-blue-100 text-blue-800",
      "tournoi" => "bg-purple-100 text-purple-800",
      "coaching_prive" => "bg-orange-100 text-orange-800"
    }
    classes[session_type] || "bg-gray-100 text-gray-800"
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

  def humanize_credit_transaction_type(transaction_type)
    case transaction_type
    when "purchase"
      "Achat"
    when "training_payment"
      "Paiement d'entraînement"
    when "free_play_payment"
      "Paiement de jeu libre"
    when "private_coaching_payment"
      "Paiement de coaching privé"
    when "refund"
      "Remboursement"
    when "manual_adjustment"
      "Ajustement de l'admin"
    else
      "Transaction"
    end
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
end
