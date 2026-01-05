import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const firstTab = this.tabTargets[0]?.dataset?.group
    if (firstTab) {
      this.showGroup(firstTab)
    }
  }

  switch(event) {
    event.preventDefault()
    event.stopPropagation()
    const groupId = event.currentTarget?.dataset?.group
    if (!groupId) return
    this.showGroup(groupId)
  }

  showGroup(groupId) {
    // Update tabs
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.group === groupId
      const levelColor = this.getLevelColor(tab)
      
      if (isActive) {
        tab.classList.add("active")
        tab.style.borderColor = levelColor
        tab.style.color = levelColor
      } else {
        tab.classList.remove("active")
        tab.style.borderColor = "transparent"
        tab.style.color = "#6b7280"
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.group === groupId) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }

  getLevelColor(tab) {
    // Get color from data attribute first (more reliable)
    const color = tab.dataset.levelColor
    if (color) {
      return color
    }
    
    // Fallback: extract color from the badge inside the tab
    const badge = tab.querySelector("span[style*='background-color']")
    if (badge) {
      const style = badge.getAttribute("style")
      const match = style.match(/background-color:\s*([^;]+)/)
      if (match) {
        return match[1].trim()
      }
    }
    return "#ef4444" // fallback color
  }
}

