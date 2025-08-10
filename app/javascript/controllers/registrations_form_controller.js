import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  addParticipant(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  removeParticipant(event) {
    event.preventDefault()
    const wrapper = event.target.closest("[data-registration-form-target='participant']")
    if (wrapper.querySelector("input[name*='_destroy']")) {
      wrapper.querySelector("input[name*='_destroy']").value = "1"
      wrapper.classList.add("hidden")
    } else {
      wrapper.remove()
    }
  }
}
