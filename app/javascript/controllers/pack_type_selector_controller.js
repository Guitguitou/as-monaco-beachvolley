import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "creditsField", "stageField"]

  connect() {
    this.toggleFields()
  }

  change() {
    this.toggleFields()
  }

  toggleFields() {
    const packType = this.selectTarget.value
    
    // Reset visibility
    if (this.hasCreditsFieldTarget) {
      this.creditsFieldTarget.style.display = "none"
    }
    if (this.hasStageFieldTarget) {
      this.stageFieldTarget.style.display = "none"
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
        break
      case "licence":
        // No additional fields needed for licence
        break
    }
  }
}
