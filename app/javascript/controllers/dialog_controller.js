import { Controller } from "@hotwired/stimulus"

// Ouvre un <dialog> natif en modale. Un clic sur le fond la ferme.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
