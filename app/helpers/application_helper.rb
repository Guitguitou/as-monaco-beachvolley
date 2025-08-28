module ApplicationHelper
  def level_badge(level)
    content_tag :span, level.name,
    class: "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold text-white",
    style: "background-color: #{level.color};"
  end

  def get_session_type_label(session_type)
    labels = {
      'entrainement' => 'Entraînement',
      'jeu_libre' => 'Jeu libre',
      'tournoi' => 'Tournoi',
      'coaching_prive' => 'Coaching privé'
    }
    labels[session_type] || session_type.humanize
  end

  def session_type_icon(session_type)
    icons = {
      'entrainement' => 'dumbbell',
      'jeu_libre' => 'volleyball',
      'tournoi' => 'trophy',
      'coaching_prive' => 'shield-user'
    }
    icons[session_type] || 'volleyball'
  end

  def get_session_type_classes(session_type)
    classes = {
      'entrainement' => 'bg-green-100 text-green-800',
      'jeu_libre' => 'bg-blue-100 text-blue-800',
      'tournoi' => 'bg-purple-100 text-purple-800',
      'coaching_prive' => 'bg-orange-100 text-orange-800'
    }
    classes[session_type] || 'bg-gray-100 text-gray-800'
  end

  def nav_link(name, path, icon:)
    active = current_page?(path)
    classes = [
      "flex items-center gap-2 px-3 py-2 rounded-md",
      "hover:bg-gray-100 text-gray-800 font-medium",
      active ? "border-l-4 border-asmbv-red bg-asmbv-red-light text-asmbv-red font-semibold" : ""
    ].join(" ")

    content_tag :div do
      link_to path, class: classes do
        concat lucide_icon(icon, class: "w-5 h-5 #{active ? 'text-asmbv-red' : 'text-gray-500'}")
        concat content_tag(:span, name)
      end
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
    current_direction = params[:direction] == 'desc' ? 'desc' : 'asc'
    next_direction = (current_sort == key.to_s && current_direction == 'asc') ? 'desc' : 'asc'

    url_params = preserve.merge(action: :index, sort: key, direction: next_direction, page: 1)

    link_to url_params, class: "inline-flex items-center gap-1 hover:text-asmbv-red" do
      concat content_tag(:span, title)
      if current_sort == key.to_s
        icon_name = current_direction == 'asc' ? 'chevron-up' : 'chevron-down'
        concat lucide_icon(icon_name, size: 14, class: 'text-gray-600')
      end
    end
  end
end
