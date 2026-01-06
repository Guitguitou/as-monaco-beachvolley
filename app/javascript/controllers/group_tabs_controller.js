import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "mobileMenu", "mobileButton", "mobileOverlay", "mobileMenuItem", "mobileButtonLabel", "mobileButtonBadge"]

  connect() {
    this.opened = false
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
    // Close mobile menu if open
    if (this.opened) {
      this.closeMobileMenu()
    }
  }

  toggleMobileMenu() {
    this.opened ? this.closeMobileMenu() : this.openMobileMenu()
  }

  openMobileMenu() {
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.remove("hidden")
    }
    if (this.hasMobileOverlayTarget) {
      this.mobileOverlayTarget.classList.remove("hidden")
    }
    if (this.hasMobileButtonTarget) {
      this.mobileButtonTarget.classList.add("active")
    }
    this.opened = true
  }

  closeMobileMenu() {
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.add("hidden")
    }
    if (this.hasMobileOverlayTarget) {
      this.mobileOverlayTarget.classList.add("hidden")
    }
    if (this.hasMobileButtonTarget) {
      this.mobileButtonTarget.classList.remove("active")
    }
    this.opened = false
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

    // Update mobile menu items
    if (this.hasMobileMenuItemTargets) {
      this.mobileMenuItemTargets.forEach(item => {
        const isActive = item.dataset.group === groupId
        const levelColor = this.getLevelColorFromItem(item)
        const checkIcon = item.querySelector(".check-icon")
        const groupName = item.querySelector("span.font-medium")?.textContent || ""
        const levelBadge = item.querySelector("span[style*='background-color']")
        const levelName = levelBadge?.textContent?.trim() || ""
        
        if (isActive) {
          item.classList.add("active")
          item.style.borderLeftColor = levelColor
          item.style.backgroundColor = `${levelColor}15`
          if (checkIcon) {
            checkIcon.classList.remove("hidden")
            checkIcon.querySelector("svg").style.color = levelColor
          }
          // Update mobile button label and badge
          if (this.hasMobileButtonLabelTarget) {
            this.mobileButtonLabelTarget.textContent = groupName
          }
          if (this.hasMobileButtonBadgeTarget) {
            this.mobileButtonBadgeTarget.textContent = levelName
            this.mobileButtonBadgeTarget.style.backgroundColor = levelColor
          }
        } else {
          item.classList.remove("active")
          item.style.borderLeftColor = "transparent"
          item.style.backgroundColor = "transparent"
          if (checkIcon) {
            checkIcon.classList.add("hidden")
          }
        }
      })
    }

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

  getLevelColorFromItem(item) {
    const color = item.dataset.levelColor
    if (color) {
      return color
    }
    return "#ef4444"
  }
}

