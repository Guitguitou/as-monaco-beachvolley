import { Controller } from "@hotwired/stimulus"

// Ajout / suppression dynamique de créneaux dans le formulaire d'annonce.
// Usage :
//   <div data-controller="nested-slots">
//     <template data-nested-slots-target="template"> ...ligne de créneau... </template>
//     <div data-nested-slots-target="list"> ...lignes existantes... </div>
//     <button data-action="nested-slots#add">Ajouter un créneau</button>
export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-slots-row]")
    if (!row) return

    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField) {
      // Créneau déjà persisté : on le marque pour destruction et on le masque.
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
