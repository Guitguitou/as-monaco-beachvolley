import { Controller } from "@hotwired/stimulus"

// Soumet le formulaire de filtres d'un tableau à chaque changement ; la
// saisie libre attend une courte pause pour ne pas lancer une requête par touche.
// Les champs de filtre vivent dans l'en-tête du tableau, hors du formulaire
// (attribut `form`), pour que les lignes puissent porter leurs propres boutons.
export default class extends Controller {
  static targets = ["form"]
  static values = { delay: { type: Number, default: 300 } }

  formTargetConnected(form) {
    // Les champs vides n'encombrent pas l'URL partageable.
    form.addEventListener("formdata", (event) => {
      for (const [key, value] of [...event.formData.entries()]) {
        if (value === "") event.formData.delete(key)
      }
    })
  }

  submit() {
    clearTimeout(this.timeout)
    this.formTarget.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.formTarget.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
