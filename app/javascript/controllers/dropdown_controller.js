// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.contentTarget.classList.remove("hidden")
    this.contentTarget.classList.add("block")
    document.addEventListener("click", this.boundCloseOnClickOutside)
  }

  close() {
    this.contentTarget.classList.add("hidden")
    this.contentTarget.classList.remove("block")
    document.removeEventListener("click", this.boundCloseOnClickOutside)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
