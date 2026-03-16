import { Controller } from "@hotwired/stimulus"

// Tutorial modal for "On joue ?" - multi-step walkthrough
export default class extends Controller {
  static targets = ["modal", "slide", "indicator", "nextButton", "prevButton"]
  static values = { current: { type: Number, default: 1 }, total: { type: Number, default: 3 } }

  open() {
    this.currentValue = 1
    this.showSlide(1)
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  next(event) {
    event?.preventDefault()
    if (this.currentValue < this.totalValue) {
      this.currentValue++
      this.showSlide(this.currentValue)
    } else {
      this.close()
    }
  }

  prev(event) {
    event?.preventDefault()
    if (this.currentValue > 1) {
      this.currentValue--
      this.showSlide(this.currentValue)
    }
  }

  showSlide(step) {
    this.slideTargets.forEach((el, i) => {
      el.classList.toggle("hidden", i + 1 !== step)
    })
    this.indicatorTargets?.forEach((el, i) => {
      el.classList.toggle("bg-asmbv-red", i + 1 === step)
      el.classList.toggle("bg-gray-300", i + 1 !== step)
    })
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.textContent = step === this.totalValue ? "Compris" : "Suivant"
    }
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.classList.toggle("invisible", step === 1)
    }
  }

}
