# frozen_string_literal: true

# Graphiques des dashboards admin : palette catégorielle validée (contraste
# et daltonisme), ordre fixe des couleurs, nombres à la française.
Chartkick.options = {
  colors: %w[#2a78d6 #eb6834 #1baf7a #eda100 #e87ba4 #008300 #6250d6 #e34948],
  thousands: " ",
  decimal: ",",
  height: "280px",
  library: {
    plugins: { legend: { position: "bottom", labels: { boxWidth: 12 } } },
    scales: { x: { grid: { display: false } }, y: { grid: { color: "#eeeeee" }, beginAtZero: true } }
  }
}
