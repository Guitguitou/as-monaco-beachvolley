import { Controller } from "@hotwired/stimulus"

// Élément masquable par l'utilisateur, mémorisé dans son navigateur.
// Caché par défaut : il ne s'affiche que s'il n'a pas déjà été fermé.
export default class extends Controller {
  static values = { key: String }

  connect() {
    if (!this.read()) this.element.classList.remove("hidden")
  }

  dismiss() {
    this.element.classList.add("hidden")
    try { localStorage.setItem(this.keyValue, "1") } catch (_) {}
  }

  read() {
    try { return localStorage.getItem(this.keyValue) } catch (_) { return null }
  }
}
