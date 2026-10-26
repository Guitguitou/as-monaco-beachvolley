import { Controller } from "@hotwired/stimulus"

// Soumet le formulaire de filtres d'un tableau à chaque changement ; la
// saisie libre attend une courte pause pour ne pas lancer une requête par touche.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    // Les champs vides n'encombrent pas l'URL partageable.
    this.element.addEventListener("formdata", (event) => {
      for (const [key, value] of [...event.formData.entries()]) {
        if (value === "") event.formData.delete(key)
      }
    })
  }

  submit() {
    clearTimeout(this.timeout)
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
