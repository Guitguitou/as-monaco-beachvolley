import { Controller } from "@hotwired/stimulus"

// Affiche le panneau dont la clé correspond à l'option sélectionnée.
// Voir SegmentedControlComponent. Les contrôleurs imbriqués ne se marchent pas
// dessus : Stimulus limite les cibles au contrôleur le plus proche.
export default class extends Controller {
  static targets = ["option", "panel"]

  select(event) {
    this.show(event.currentTarget.dataset.key)
  }

  show(key) {
    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-selected", option.dataset.key === key)
    })
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.key !== key
    })
  }
}
