import { Controller } from "@hotwired/stimulus"

// Connector: data-controller="push-notifications"
export default class extends Controller {
  static values = {
    vapidPublicKey: String
  }

  static targets = ["enableButton", "reenableButton", "disableButton", "deniedHelp"]

  // Choix explicite de couper les notifications sur cet appareil : sans lui,
  // la permission « granted » réabonnerait l'appareil à chaque chargement.
  static OPT_OUT_KEY = "push-notifications-opt-out"

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
      
      if (permission === "granted" && !this.optedOut) {
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
        this.optedOut = false
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

  // Réactive après une désactivation : la permission étant déjà accordée,
  // aucun prompt navigateur ne réapparaît.
  async enable() {
    this.optedOut = false
    const registration = await navigator.serviceWorker.ready
    await this.subscribe(registration)
    this.reload()
  }

  async disable() {
    this.optedOut = true
    await this.unsubscribe()
    this.reload()
  }

  async updateButtonVisibility() {
    const permission = "Notification" in window ? Notification.permission : "denied"
    const subscribed = permission === "granted" && !this.optedOut && await this.hasSubscription()

    // Plusieurs boutons coexistent (navbar, menu mobile, réglages du profil) :
    // on itère sur tous les targets, pas seulement le premier.
    this.toggle(this.enableButtonTargets, permission === "default")
    this.toggle(this.reenableButtonTargets, permission === "granted" && !subscribed)
    this.toggle(this.disableButtonTargets, subscribed)
    this.toggle(this.deniedHelpTargets, permission === "denied")
  }

  toggle(elements, visible) {
    elements.forEach((element) => {
      element.style.display = visible ? "" : "none"
    })
  }

  async hasSubscription() {
    if (!("serviceWorker" in navigator)) return false

    const registration = await navigator.serviceWorker.getRegistration()
    return Boolean(await registration?.pushManager.getSubscription())
  }

  get optedOut() {
    try {
      return localStorage.getItem(this.constructor.OPT_OUT_KEY) === "true"
    } catch {
      return false
    }
  }

  set optedOut(value) {
    try {
      if (value) {
        localStorage.setItem(this.constructor.OPT_OUT_KEY, "true")
      } else {
        localStorage.removeItem(this.constructor.OPT_OUT_KEY)
      }
    } catch {
      // Stockage indisponible (navigation privée) : rien à mémoriser.
    }
  }

  // Le statut du profil (nombre d'appareils) est rendu côté serveur.
  reload() {
    if (window.Turbo) {
      window.Turbo.visit(window.location.href, { action: "replace" })
    } else {
      window.location.reload()
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
