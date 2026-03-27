// app/javascript/controllers/session_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "type", "price", "userGroupCoach", "userGroupResponsable", "userGroupAll",
    "startAt", "endAt", "endAtHidden", "registrationOpensWrapper",
    "terrain", "terrainWarning"
  ]
  static values = {
    prices: Object,
    terrainClosures: { type: Array, default: [] }
  }

  connect() {
    this.updateUserSelect()
    this.updatePrice()
    this.updateEndTime()
    this.updateRegistrationOpensVisibility()
    this.filterTerrainOptions()
  }

  onTypeChange() {
    this.updateUserSelect()
    this.updatePrice()
    this.updateRegistrationOpensVisibility()

    const lockTypes = ["entrainement", "jeu_libre", "coaching_prive"]
    const shouldLock = lockTypes.includes(this.typeTarget.value)

    if (shouldLock) {
      this.updateEndTime()
    } else {
      if (this.hasEndAtTarget) {
        this.endAtTarget.classList.remove("bg-gray-100")
        this.endAtTarget.readOnly = false
        this.endAtTarget.disabled = false
      }
    }
  }

  onStartChange() {
    this.updateEndTime()
    this.filterTerrainOptions()
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
    } else if (value === "tournoi" || value === "stage") {
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
      if (shouldLock) {
        this.endAtTarget.classList.add("bg-gray-100", "text-gray-500", "cursor-not-allowed")
        this.endAtTarget.readOnly = true
        this.endAtTarget.disabled = true
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
      this.endAtTarget.disabled = true
      this.endAtTarget.classList.add("bg-gray-100", "text-gray-500", "cursor-not-allowed")
    } else {
      this.endAtTarget.readOnly = false
      this.endAtTarget.disabled = false
      this.endAtTarget.classList.remove("bg-gray-100", "text-gray-500", "cursor-not-allowed")
    }
  }

  updateRegistrationOpensVisibility() {
    if (!this.hasRegistrationOpensWrapperTarget) return
    const isTraining = this.typeTarget.value === "entrainement"
    this.registrationOpensWrapperTarget.style.display = isTraining ? "block" : "none"
  }

  filterTerrainOptions() {
    if (!this.hasTerrainTarget) return

    const slotDateStr = this.#slotDateIsoFromStart()
    const closures = this.terrainClosuresValue || []
    const unavailable = new Set()

    if (slotDateStr) {
      for (const c of closures) {
        if (!c || !c.starts_on || !c.ends_on || !c.terrain) continue
        if (slotDateStr >= c.starts_on && slotDateStr <= c.ends_on) {
          unavailable.add(c.terrain)
        }
      }
    }

    let hadInvalidSelection = false
    const opts = [...this.terrainTarget.options]

    opts.forEach((opt) => {
      if (!opt.value) {
        opt.disabled = false
        opt.removeAttribute("title")
        return
      }
      if (!slotDateStr) {
        opt.disabled = false
        opt.removeAttribute("title")
        return
      }
      const dis = unavailable.has(opt.value)
      opt.disabled = dis
      if (dis) opt.title = "Terrain indisponible à cette date"
      else opt.removeAttribute("title")
    })

    const current = this.terrainTarget.value
    if (current && unavailable.has(current)) {
      hadInvalidSelection = true
      const firstOk = opts.find((o) => o.value && !o.disabled)
      this.terrainTarget.value = firstOk ? firstOk.value : ""
    }

    if (this.hasTerrainWarningTarget) {
      if (hadInvalidSelection) {
        this.terrainWarningTarget.textContent =
          "Ce terrain est indisponible à la date choisie ; sélectionnez un autre terrain ou modifiez la date."
        this.terrainWarningTarget.classList.remove("hidden")
      } else {
        this.terrainWarningTarget.classList.add("hidden")
      }
    }
  }

  #slotDateIsoFromStart() {
    if (!this.hasStartAtTarget || !this.startAtTarget.value) return null
    const d = this.#parseDatetimeLocal(this.startAtTarget.value)
    if (!d) return null
    const pad = (n) => String(n).padStart(2, "0")
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  }

  #parseDatetimeLocal(value) {
    if (!value) return null
    const m = value.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/)
    if (!m) return null
    const [_, y, mo, d, h, mi] = m
    return new Date(Number(y), Number(mo) - 1, Number(d), Number(h), Number(mi))
  }
}
