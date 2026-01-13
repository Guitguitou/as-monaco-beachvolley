import { Controller } from "@hotwired/stimulus"

// Connector: data-controller="push-notifications"
export default class extends Controller {
  static values = {
    vapidPublicKey: String
  }

  static targets = ["enableButton"]

  connect() {
    this.checkSupport()
    this.registerServiceWorker()
    this.updateButtonVisibility()
  }

  async checkSupport() {
    if (!("serviceWorker" in navigator)) {
      console.warn("Service Workers are not supported in this browser")
      return false
    }

    if (!("PushManager" in window)) {
      console.warn("Push notifications are not supported in this browser")
      return false
    }

    return true
  }

  async registerServiceWorker() {
    try {
      const registration = await navigator.serviceWorker.register("/service-worker.js")
      console.log("Service Worker registered:", registration)

      // Check current permission status (without prompting)
      const permission = Notification.permission
      
      if (permission === "granted") {
        // Already granted, subscribe automatically
        await this.subscribe(registration)
      } else if (permission === "default") {
        // Permission not yet asked, don't ask automatically
        // User will need to click a button to enable notifications
        console.log("Notification permission not yet requested. User can enable via button.")
      } else {
        // Permission denied
        console.log("Notification permission denied by user.")
      }
      
      this.updateButtonVisibility()
    } catch (error) {
      console.error("Service Worker registration failed:", error)
    }
  }

  // Method to request permission (called by user action, e.g., button click)
  async requestPermission() {
    try {
      const permission = await Notification.requestPermission()
      
      if (permission === "granted") {
        const registration = await navigator.serviceWorker.ready
        await this.subscribe(registration)
        this.updateButtonVisibility()
        
        // Show success message (optional)
        if (window.Turbo) {
          // You could use Turbo Flash messages here if available
          console.log("Notifications activées avec succès !")
        }
        
        return true
      } else {
        console.log("Notification permission denied")
        alert("Les notifications ont été refusées. Vous pouvez les activer plus tard dans les paramètres de votre navigateur.")
        this.updateButtonVisibility()
        return false
      }
    } catch (error) {
      console.error("Error requesting notification permission:", error)
      return false
    }
  }

  updateButtonVisibility() {
    if (!this.hasEnableButtonTarget) return
    
    const permission = Notification.permission
    const button = this.enableButtonTarget
    
    if (permission === "default") {
      // Permission not yet asked, show button
      button.style.display = "flex"
    } else {
      // Permission already granted or denied, hide button
      button.style.display = "none"
    }
  }

  async subscribe(registration) {
    try {
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        // Already subscribed, sync with server
        await this.syncSubscription(subscription)
        return
      }

      // Create new subscription
      const newSubscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      await this.syncSubscription(newSubscription)
    } catch (error) {
      console.error("Push subscription failed:", error)
    }
  }

  async syncSubscription(subscription) {
    const subscriptionData = {
      endpoint: subscription.endpoint,
      p256dh: this.arrayBufferToBase64(subscription.getKey("p256dh")),
      auth: this.arrayBufferToBase64(subscription.getKey("auth"))
    }

    try {
      const response = await fetch("/api/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ push_subscription: subscriptionData })
      })

      if (response.ok) {
        console.log("Push subscription saved to server")
      } else {
        console.error("Failed to save push subscription:", await response.text())
      }
    } catch (error) {
      console.error("Error syncing subscription:", error)
    }
  }

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        await subscription.unsubscribe()

        // Remove from server
        const response = await fetch("/api/push_subscriptions", {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ endpoint: subscription.endpoint })
        })

        if (response.ok) {
          console.log("Push subscription removed")
        }
      }
    } catch (error) {
      console.error("Error unsubscribing:", error)
    }
  }

  // Helper: Convert VAPID public key from base64 URL to Uint8Array
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }

  // Helper: Convert ArrayBuffer to base64
  arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return window.btoa(binary)
  }
}
