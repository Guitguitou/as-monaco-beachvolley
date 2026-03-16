import { Controller } from "@hotwired/stimulus"

// Multi-step wizard for "Je suis dispo" form
export default class extends Controller {
  static targets = ["step", "nav"]
  static values = { current: { type: Number, default: 1 }, total: { type: Number, default: 3 } }

  connect() {
    this.showStep(this.currentValue)
  }

  next(event) {
    event?.preventDefault()
    if (this.currentValue < this.totalValue) {
      this.currentValue++
      this.showStep(this.currentValue)
    }
  }

  prev(event) {
    event?.preventDefault()
    if (this.currentValue > 1) {
      this.currentValue--
      this.showStep(this.currentValue)
    }
  }

  goTo(event) {
    event?.preventDefault()
    const step = parseInt(event.currentTarget?.dataset?.step, 10)
    if (step >= 1 && step <= this.totalValue) {
      this.currentValue = step
      this.showStep(this.currentValue)
    }
  }

  showStep(step) {
    this.stepTargets.forEach((el, i) => {
      const isActive = i + 1 === step
      el.classList.toggle("hidden", !isActive)
    })
    this.updateNav(step)
  }

  updateNav(step) {
    if (!this.hasNavTarget) return
    this.navTargets.forEach((el, i) => {
      const stepNum = i + 1
      const isActive = stepNum === step
      const isPast = stepNum < step
      el.classList.toggle("border-asmbv-red", isActive)
      el.classList.toggle("text-asmbv-red", isActive)
      el.classList.toggle("border-transparent", !isActive)
      el.classList.toggle("text-gray-500", !isActive && !isPast)
      el.classList.toggle("text-gray-700", isPast && !isActive)
    })
  }
}
