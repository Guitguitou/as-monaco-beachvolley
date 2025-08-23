// app/javascript/controllers/sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.opened = false
  }

  toggle() {
    this.opened ? this.close() : this.open()
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
    this.opened = true
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
    this.opened = false
  }
}
