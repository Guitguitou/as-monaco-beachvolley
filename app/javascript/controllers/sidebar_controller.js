// app/javascript/controllers/sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle() {
    this.sidebarTarget.classList.toggle("-translate-x-full")
  }
}
