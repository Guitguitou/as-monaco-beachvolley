module ApplicationHelper
  def level_badge(level)
    content_tag :span, level.name,
    class: "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold text-white",
    style: "background-color: #{level.color};"
  end
end
