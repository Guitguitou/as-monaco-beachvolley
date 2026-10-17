import { Controller } from "@hotwired/stimulus"

// Partage un lien : feuille de partage native sur mobile (WhatsApp, SMS…),
// sinon copie dans le presse-papiers avec un retour visuel sur le bouton.
export default class extends Controller {
  static targets = ["label"]
  static values = { url: String, title: String }

  async share() {
    if (navigator.share) {
      try {
        await navigator.share({ title: this.titleValue, url: this.urlValue })
      } catch (_) {
        // partage annulé par l'utilisateur
      }
      return
    }

    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.flash("Lien copié")
    } catch (_) {
      window.prompt("Copie ce lien :", this.urlValue)
    }
  }

  flash(text) {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = text
    setTimeout(() => { this.labelTarget.textContent = original }, 2000)
  }
}
