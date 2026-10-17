import { Controller } from "@hotwired/stimulus"

// Cadrage de la photo de profil dans le cercle de l'avatar.
//
// On ne recadre pas le fichier : on enregistre un point focal (x, y en %) et un
// zoom, que AvatarComponent réapplique en CSS avec la même formule.
export default class extends Controller {
  static targets = ["input", "image", "placeholder", "zoom", "x", "y", "editor", "remove"]

  connect() {
    this.render()
  }

  pick() {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = URL.createObjectURL(file)
    this.imageTarget.src = this.objectUrl
    this.xTarget.value = 50
    this.yTarget.value = 50
    this.zoomTarget.value = 1
    if (this.hasRemoveTarget) this.removeTarget.checked = false
    this.render()
  }

  disconnect() {
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
  }

  startDrag(event) {
    if (!this.imageTarget.getAttribute("src")) return

    event.preventDefault()
    this.drag = { x: event.clientX, y: event.clientY, focusX: this.focusX, focusY: this.focusY }
    this.imageTarget.parentElement.setPointerCapture(event.pointerId)
  }

  moveDrag(event) {
    if (!this.drag) return

    // Glisser vers la droite révèle la gauche de l'image : le point focal recule.
    const size = this.imageTarget.parentElement.clientWidth
    const factor = 100 / (size * this.zoom)
    this.xTarget.value = this.clamp(this.drag.focusX - (event.clientX - this.drag.x) * factor)
    this.yTarget.value = this.clamp(this.drag.focusY - (event.clientY - this.drag.y) * factor)
    this.render()
  }

  endDrag() {
    this.drag = null
  }

  render() {
    const hasImage = Boolean(this.imageTarget.getAttribute("src"))
    this.imageTarget.hidden = !hasImage
    this.placeholderTarget.hidden = hasImage
    this.editorTarget.hidden = !hasImage

    const focus = `${this.focusX}% ${this.focusY}%`
    this.imageTarget.style.objectPosition = focus
    this.imageTarget.style.transformOrigin = focus
    this.imageTarget.style.transform = `scale(${this.zoom})`
  }

  get focusX() { return parseFloat(this.xTarget.value) || 50 }
  get focusY() { return parseFloat(this.yTarget.value) || 50 }
  get zoom() { return parseFloat(this.zoomTarget.value) || 1 }

  clamp(value) {
    return Math.min(100, Math.max(0, value)).toFixed(1)
  }
}
