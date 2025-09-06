// app/javascript/controllers/collapse_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "chevron"]

  connect() {
    this.isOpen = this.element.dataset.open === "true"
    this.renderState()
  }

  toggle() {
    this.isOpen = !this.isOpen
    this.renderState()
  }

  renderState() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.isOpen)
    }
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", this.isOpen)
    }
  }
}
