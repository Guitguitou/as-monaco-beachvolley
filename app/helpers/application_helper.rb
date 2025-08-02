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
      active ? "border-l-4 border-asmbv-red bg-gray-100" : ""
    ].join(" ")

    content_tag :div do
      link_to path, class: classes do
        concat lucide_icon(icon, class: 'w-5 h-5 text-asmbv-red')
        concat content_tag(:span, name)
      end
    end
  end
end
