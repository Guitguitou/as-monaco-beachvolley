// Service Worker for handling push notifications
self.addEventListener("push", function(event) {
  let data = {}
  
  if (event.data) {
    try {
      data = event.data.json()
    } catch (e) {
      data = { title: "Notification", body: event.data.text() || "Nouvelle notification" }
    }
  }

  const options = {
    body: data.body || "Nouvelle notification",
    icon: data.icon || "/logo.png", // Utilise le logo de l'app
    badge: data.badge || "/logo.png", // Badge dans la barre de notification
    image: data.image || null, // Image grande (optionnelle, pour certaines plateformes)
    data: data.data || {},
    tag: data.tag || "default", // Permet de regrouper les notifications similaires
    requireInteraction: data.requireInteraction || false, // Notification reste visible jusqu'à interaction
    vibrate: data.vibrate || [200, 100, 200], // Vibration sur mobile
    silent: data.silent || false, // Notification silencieuse
    timestamp: Date.now(), // Timestamp de la notification
    actions: data.actions || [], // Actions rapides (optionnel, selon le navigateur)
    dir: "ltr", // Direction du texte
    lang: "fr" // Langue
  }

  event.waitUntil(
    self.registration.showNotification(data.title || "AS Monaco Beach Volley", options)
  )
})

// Handle notification click
self.addEventListener("notificationclick", function(event) {
  event.notification.close()

  const urlToOpen = event.notification.data.url || "/"

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(function(clientList) {
      // Check if there's already a window/tab open with the target URL
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i]
        if (client.url === urlToOpen && "focus" in client) {
          return client.focus()
        }
      }
      // If not, open a new window/tab
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen)
      }
    })
  )
})

// Handle notification close
self.addEventListener("notificationclose", function(event) {
  // Could track analytics here if needed
  console.log("Notification closed:", event.notification.tag)
})
