import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Show first tab by default
    const firstTab = this.tabTargets[0]?.dataset?.tab || "all"
    this.showTab(firstTab)
  }

  switch(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const tabName = event.currentTarget?.dataset?.tab
    if (!tabName) {
      console.error("No tab name found")
      return
    }
    
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      if (isActive) {
        tab.classList.add("border-asmbv-red", "text-asmbv-red")
        tab.classList.remove("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
      } else {
        tab.classList.remove("border-asmbv-red", "text-asmbv-red")
        tab.classList.add("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.panel === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
