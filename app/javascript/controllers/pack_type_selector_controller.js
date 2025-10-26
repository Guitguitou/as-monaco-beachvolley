import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "creditsField", "stageField", "stageSelect"]

  connect() {
    this.toggleFields()
  }

  change() {
    this.toggleFields()
  }

  toggleFields() {
    const packType = this.selectTarget.value
    
    // Reset visibility and required attributes
    if (this.hasCreditsFieldTarget) {
      this.creditsFieldTarget.style.display = "none"
    }
    if (this.hasStageFieldTarget) {
      this.stageFieldTarget.style.display = "none"
    }
    if (this.hasStageSelectTarget) {
      this.stageSelectTarget.removeAttribute("required")
    }
    
    // Show relevant fields based on pack type
    switch(packType) {
      case "credits":
        if (this.hasCreditsFieldTarget) {
          this.creditsFieldTarget.style.display = "block"
        }
        break
      case "stage":
        if (this.hasStageFieldTarget) {
          this.stageFieldTarget.style.display = "block"
        }
        if (this.hasStageSelectTarget) {
          this.stageSelectTarget.setAttribute("required", "required")
        }
        break
      case "licence":
        // No additional fields needed for licence
        break
    }
  }
}
