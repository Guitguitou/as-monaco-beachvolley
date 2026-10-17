import { Controller } from "@hotwired/stimulus"

// Avant d'enregistrer une session, le Staff choisit pour chaque participant
// retiré après le délai d'annulation : désinscription tardive ou excusée.
export default class extends Controller {
  static targets = ["participants", "dialog", "row"]

  confirm(event) {
    if (this.confirmed) return

    const selected = new Set(Array.from(this.participantsTarget.selectedOptions, (option) => option.value))
    let lateRemovals = 0
    this.rowTargets.forEach((row) => {
      const removed = !selected.has(row.dataset.userId)
      row.hidden = !removed
      row.querySelector("input").disabled = !removed
      if (removed) lateRemovals += 1
    })
    if (lateRemovals === 0) return

    event.preventDefault()
    this.dialogTarget.showModal()
  }

  submit() {
    this.confirmed = true
    this.dialogTarget.close()
    this.element.requestSubmit()
  }

  cancel() {
    this.dialogTarget.close()
  }
}
