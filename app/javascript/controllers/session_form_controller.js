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
    
    // Cacher et désactiver tous les groupes
    this.userGroupCoachTarget.classList.add("hidden")
    this.userGroupResponsableTarget.classList.add("hidden")
    this.userGroupAllTarget.classList.add("hidden")
    
    // Désactiver tous les selects
    this.userGroupCoachTarget.querySelector("select").disabled = true
    this.userGroupResponsableTarget.querySelector("select").disabled = true
    this.userGroupAllTarget.querySelector("select").disabled = true

    // Afficher et activer le bon groupe selon le type
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
}
