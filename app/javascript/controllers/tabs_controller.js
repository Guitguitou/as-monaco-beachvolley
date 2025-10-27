import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  switchTab(event) {
    event.preventDefault()
    
    const tabId = event.currentTarget.dataset.tab
    const url = new URL(event.currentTarget.href)
    
    // Update URL without page reload
    history.pushState({}, '', url)
    
    // Update active tab styling
    this.updateActiveTab(tabId)
    
    // Load tab content via Turbo Frame
    this.loadTabContent(tabId)
  }
  
  updateActiveTab(activeTabId) {
    // Remove active class from all tabs
    this.element.querySelectorAll('[data-tab]').forEach(tab => {
      tab.classList.remove('bg-asmbv-red', 'text-white')
      tab.classList.add('text-gray-500', 'hover:text-gray-700', 'hover:bg-gray-100')
    })
    
    // Add active class to current tab
    const activeTab = this.element.querySelector(`[data-tab="${activeTabId}"]`)
    if (activeTab) {
      activeTab.classList.add('bg-asmbv-red', 'text-white')
      activeTab.classList.remove('text-gray-500', 'hover:text-gray-700', 'hover:bg-gray-100')
    }
  }
  
  loadTabContent(tabId) {
    // For now, just reload the page to get the new tab content
    // In the future, this could be optimized with Turbo Frames
    window.location.reload()
  }
}
