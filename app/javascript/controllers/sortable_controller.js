import { Controller } from "@hotwired/stimulus"

// Glisser-déposer par poignée, souris et tactile (pointer events).
// Au lâcher, envoie l'ordre des data-sortable-id en PATCH à urlValue.
export default class extends Controller {
  static targets = ["item", "handle"]
  static values = { url: String, param: { type: String, default: "ids" } }

  start(event) {
    if (event.button !== 0) return
    event.preventDefault()
    this.dragged = event.target.closest("[data-sortable-target='item']")
    this.initialOrder = this.order()
    this.dragged.classList.add("opacity-50", "ring-2", "ring-asmbv-red")
    this.onMove = this.move.bind(this)
    this.onEnd = this.end.bind(this)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onEnd, { once: true })
    window.addEventListener("pointercancel", this.onEnd, { once: true })
  }

  move(event) {
    const over = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-sortable-target='item']")
    if (!over || over === this.dragged || !this.element.contains(over)) return

    const rect = over.getBoundingClientRect()
    const horizontal = getComputedStyle(this.element).display.includes("grid") || getComputedStyle(this.element).flexDirection === "row"
    const after = horizontal
      ? event.clientX > rect.left + rect.width / 2
      : event.clientY > rect.top + rect.height / 2
    over.parentNode.insertBefore(this.dragged, after ? over.nextSibling : over)
  }

  end() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onEnd)
    window.removeEventListener("pointercancel", this.onEnd)
    this.dragged.classList.remove("opacity-50", "ring-2", "ring-asmbv-red")
    this.dragged = null

    const order = this.order()
    if (order.join() !== this.initialOrder.join()) this.save(order)
  }

  order() {
    return this.itemTargets.map((item) => item.dataset.sortableId)
  }

  async save(order) {
    const body = new FormData()
    order.forEach((id) => body.append(`${this.paramValue}[]`, id))
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      body,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        Accept: "text/vnd.turbo-stream.html, text/html"
      }
    })
    if (!response.ok) window.location.reload()
    this.dispatch("saved", { detail: { order } })
  }
}
