import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  connect() {
    // Initialize with the first tab if none is active
    if (!this.hasActiveTab()) {
      this.switchToTab(this.tabTargets[0])
    }
  }

  switchTab(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabId
    this.switchToTab(event.currentTarget)
    this.loadTabContent(tabId)
  }

  switchToTab(tabElement) {
    // Remove active class from all tabs
    this.tabTargets.forEach(tab => {
      tab.classList.remove("bg-asmbv-red", "text-white")
      tab.classList.add("text-gray-600", "hover:text-gray-900", "hover:bg-gray-100")
    })

    // Add active class to selected tab
    tabElement.classList.remove("text-gray-600", "hover:text-gray-900", "hover:bg-gray-100")
    tabElement.classList.add("bg-asmbv-red", "text-white")
  }

  loadTabContent(tabId) {
    const url = new URL(window.location)
    url.searchParams.set('tab', tabId)
    
    // Update the URL without reloading the page
    history.pushState({}, '', url)
    
    // Load the tab content via Turbo Frame
    fetch(url.toString(), {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Update the content frame
      const frame = document.getElementById('dashboard-content')
      if (frame) {
        frame.innerHTML = html
      }
    })
    .catch(error => {
      console.error('Error loading tab content:', error)
    })
  }

  hasActiveTab() {
    return this.tabTargets.some(tab => tab.classList.contains("bg-asmbv-red"))
  }
}
