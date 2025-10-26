import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["creditsField", "stageField"]

  connect() {
    this.toggleFields()
  }

  change() {
    this.toggleFields()
  }

  toggleFields() {
    const packType = this.element.value
    
    // Reset visibility
    this.creditsFieldTarget.style.display = "none"
    this.stageFieldTarget.style.display = "none"
    
    // Show relevant fields based on pack type
    switch(packType) {
      case "credits":
        this.creditsFieldTarget.style.display = "block"
        break
      case "stage":
        this.stageFieldTarget.style.display = "block"
        break
      case "licence":
        // No additional fields needed for licence
        break
    }
  }
}
