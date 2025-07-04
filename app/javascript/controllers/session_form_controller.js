// app/javascript/controllers/session_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "userGroupCoach", "userGroupResponsable", "userGroupAll"]

  connect() {
    console.log("✅ SessionFormController mounted");
    this.updateUserSelect();
  }

  updateUserSelect() {
    const value = this.typeTarget.value
    this.userGroupCoachTarget.classList.add("hidden")
    this.userGroupResponsableTarget.classList.add("hidden")
    this.userGroupAllTarget.classList.add("hidden")

    if (value === "entrainement" || value === "coaching_prive") {
      this.userGroupCoachTarget.classList.remove("hidden")
    } else if (value === "jeu_libre") {
      this.userGroupResponsableTarget.classList.remove("hidden")
    } else if (value === "tournoi") {
      this.userGroupAllTarget.classList.remove("hidden")
    }
  }
}
