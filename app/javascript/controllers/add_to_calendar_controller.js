import { Controller } from "@hotwired/stimulus"

// Choisit la meilleure façon d'ajouter l'événement à l'agenda selon la plateforme :
//
// - Android : le .ics se télécharge dans les fichiers et l'utilisateur doit l'ouvrir à la
//   main. On bascule donc sur le lien Google Agenda, qui ouvre directement l'app sur
//   l'écran de création d'événement pré-rempli.
// - iOS / desktop : le .ics servi en `inline` ouvre déjà Calendar (ou l'app par défaut).
export default class extends Controller {
  static values = { googleUrl: String }

  connect() {
    if (!this.hasGoogleUrlValue || !this.isAndroid) return

    this.element.href = this.googleUrlValue
    this.element.removeAttribute("download")
    this.element.target = "_blank"
    this.element.rel = "noopener"
  }

  get isAndroid() {
    return /Android/i.test(navigator.userAgent)
  }
}
