// app/javascript/controllers/session_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "type", "price", "userGroupCoach", "userGroupResponsable", "userGroupAll",
    "startAt", "endAt", "endAtHidden"
  ]
  static values = { prices: Object }

  connect() {
    this.updateUserSelect()
    this.updatePrice()
    this.updateEndTime() // si la session est déjà partiellement remplie
  }

  onTypeChange() {
    this.updateUserSelect()
    this.updatePrice()

    const lockTypes = ["entrainement", "jeu_libre", "coaching_prive"]
    const shouldLock = lockTypes.includes(this.typeTarget.value)

    if (shouldLock) {
      // Recalcule et rend le champ en lecture seule si on a déjà un start
      this.updateEndTime()
    } else {
      // On quitte un type “locké” → redonne la main
      if (this.hasEndAtTarget) {
        this.endAtTarget.classList.remove("bg-gray-100")
        this.endAtTarget.readOnly = false
        // Optionnel : vider pour éviter une valeur figée trompeuse
        this.endAtTarget.value = ""
      }
    }
  }

  onStartChange() {
    this.updateEndTime()
  }

  onEndChange() {
    if (this.hasEndAtHiddenTarget && this.hasEndAtTarget) {
      this.endAtHiddenTarget.value = this.endAtTarget.value
    }
  }

  updateUserSelect() {
    const value = this.typeTarget.value
    this.userGroupCoachTarget.classList.add("hidden")
    this.userGroupResponsableTarget.classList.add("hidden")
    this.userGroupAllTarget.classList.add("hidden")

    this.userGroupCoachTarget.querySelector("select").disabled = true
    this.userGroupResponsableTarget.querySelector("select").disabled = true
    this.userGroupAllTarget.querySelector("select").disabled = true

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
    const type = this.typeTarget.value
    const mapping = this.pricesValue || {}
    this.priceTarget.value = mapping[type] ?? 0
  }

  updateEndTime() {
    if (!this.hasStartAtTarget || !this.hasEndAtTarget) return

    const type = this.typeTarget.value
    const lockTypes = ["entrainement", "jeu_libre", "coaching_prive"]
    const shouldLock = lockTypes.includes(type)

    if (!this.startAtTarget.value) {
      // Pas de start → si on est locké, on grise quand même endAt (lecture seule)
      if (shouldLock) {
        this.endAtTarget.classList.add("bg-gray-100", "text-gray-500", "cursor-not-allowed")
        this.endAtTarget.readOnly = true
      }
      return
    }

    if (shouldLock) {
      const parsedDate = this.#parseDatetimeLocal(this.startAtTarget.value)
      if (!parsedDate) return
      const endDate = new Date(parsedDate.getTime() + 90 * 60 * 1000)
      const pad = (n) => String(n).padStart(2, "0")
      const formatted = `${endDate.getFullYear()}-${pad(endDate.getMonth() + 1)}-${pad(endDate.getDate())}T${pad(endDate.getHours())}:${pad(endDate.getMinutes())}`

      this.endAtTarget.value = formatted
      if (this.hasEndAtHiddenTarget) this.endAtHiddenTarget.value = formatted
      this.endAtTarget.readOnly = true
      this.endAtTarget.classList.add("bg-gray-100", "text-gray-500", "cursor-not-allowed")
    } else {
      this.endAtTarget.readOnly = false
      this.endAtTarget.classList.remove("bg-gray-100", "text-gray-500", "cursor-not-allowed")
    }
  }

  #parseDatetimeLocal(value) {
    if (!value) return null
    const m = value.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/)
    if (!m) return null
    const [_, y, mo, d, h, mi] = m
    return new Date(Number(y), Number(mo) - 1, Number(d), Number(h), Number(mi))
  }
}
