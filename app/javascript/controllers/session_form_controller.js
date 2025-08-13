// app/javascript/controllers/session_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "price", "userGroupCoach", "userGroupResponsable", "userGroupAll", "start", "end"]
  static values = { prices: Object }

  connect() {
    this.updateUserSelect()
    this.updatePrice()
    this.updateEndTime()
  }

  onTypeChange() {
    this.updateUserSelect()
    this.updatePrice()
    this.updateEndTime()
  }

  onStartChange() {
    this.updateEndTime()
  }

  updateUserSelect() {
    const value = this.typeTarget.value
    
    // Cacher et désactiver tous les groupes
    this.userGroupCoachTarget.classList.add("hidden")
    this.userGroupResponsableTarget.classList.add("hidden")
    this.userGroupAllTarget.classList.add("hidden")
    
    // Désactiver tous les selects
    this.userGroupCoachTarget.querySelector("select").disabled = true
    this.userGroupResponsableTarget.querySelector("select").disabled = true
    this.userGroupAllTarget.querySelector("select").disabled = true

    // Afficher et activer le bon groupe selon le type
    if (value === "entrainement" || value === "coaching_prive") {
      this.userGroupCoachTarget.classList.remove("hidden")
      this.userGroupCoachTarget.querySelector("select").disabled = false
    } else if (value === "jeu_libre") {
      this.userGroupResponsableTarget.classList.remove("hidden")
      this.userGroupResponsableTarget.querySelector("select").disabled = false
    } else if (value === "tournoi") {
      this.userGroupAllTarget.classList.remove("hidden")
      this.userGroupAllTarget.querySelector("select").disabled = false
    }
  }

  updatePrice() {
    if (!this.hasPriceTarget) return
    try {
      const type = this.typeTarget.value
      const mapping = this.pricesValue || {}
      const price = mapping[type] ?? 0
      this.priceTarget.value = price
    } catch (_) {
      // noop
    }
  }

  updateEndTime() {
    if (!this.hasStartTarget || !this.hasEndTarget) return

    const type = this.typeTarget.value
    const lockTypes = ["entrainement", "jeu_libre", "coaching_prive"]
    const shouldLock = lockTypes.includes(type)

    if (!this.startTarget.value) return

    if (shouldLock) {
      try {
        const startDate = new Date(this.startTarget.value)
        if (isNaN(startDate.getTime())) return
        const endDate = new Date(startDate.getTime() + 90 * 60 * 1000)

        // Format to yyyy-MM-ddTHH:mm for datetime-local
        const pad = (n) => String(n).padStart(2, '0')
        const formatted = `${endDate.getFullYear()}-${pad(endDate.getMonth()+1)}-${pad(endDate.getDate())}T${pad(endDate.getHours())}:${pad(endDate.getMinutes())}`
        this.endTarget.value = formatted
        this.endTarget.readOnly = true
        this.endTarget.classList.add('bg-gray-100')
      } catch (_) { /* noop */ }
    } else {
      this.endTarget.readOnly = false
      this.endTarget.classList.remove('bg-gray-100')
    }
  }
}
