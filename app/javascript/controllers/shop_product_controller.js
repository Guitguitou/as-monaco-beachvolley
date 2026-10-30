import { Controller } from "@hotwired/stimulus"

// Fiche d'un article de la boutique : le coloris choisi change la photo, la
// coupe choisie affiche son prix et ses tailles, et désactive celles des
// autres coupes pour qu'une seule taille parte avec le formulaire.
export default class extends Controller {
  static targets = ["photo", "colorName", "price", "sizes"]

  pickColor(event) {
    const { name, photoUrl, photoAlt } = event.target.dataset
    this.colorNameTarget.textContent = name
    if (this.hasPhotoTarget && photoUrl) {
      this.photoTarget.src = photoUrl
      this.photoTarget.alt = photoAlt
    }
  }

  pickCut(event) {
    const cut = event.target
    this.priceTarget.textContent = cut.dataset.price
    this.sizesTargets.forEach((group) => {
      const active = group.dataset.cutId === cut.value
      group.hidden = !active
      group.querySelectorAll("input").forEach((input) => { input.disabled = !active })
    })
  }
}
