// app/javascript/controllers/flash_controller.js
//
// Un toast de message flash : fermeture manuelle, et disparition automatique
// pour les messages de succès / d'information.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: Boolean,
    delay: { type: Number, default: 6000 }
  }

  connect() {
    if (this.autoDismissValue) {
      this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)

    if (this.prefersReducedMotion) {
      this.element.remove()
      return
    }

    this.element.classList.add("opacity-0", "-translate-y-2")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }

  get prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
