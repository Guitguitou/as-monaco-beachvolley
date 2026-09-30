import { Controller } from "@hotwired/stimulus"

// Recherche, dépliage et « Me trouver » d'un RankingComponent.
export default class extends Controller {
  static targets = ["row", "query", "empty", "more"]
  static values = { visible: Number }

  connect() {
    this.expanded = false
  }

  filter() {
    this.render()
  }

  toggle() {
    this.expanded = !this.expanded
    this.render()
  }

  locate() {
    this.queryTarget.value = ""
    this.expanded = true
    this.render()
    const row = this.rowTargets.find((row) => row.hasAttribute("data-me"))
    if (!row) return

    row.scrollIntoView({ behavior: "smooth", block: "center" })
    row.animate([{ transform: "scale(1.03)" }, { transform: "scale(1)" }], { duration: 400, iterations: 2 })
  }

  render() {
    const query = this.normalize(this.queryTarget.value)
    let matches = 0

    this.rowTargets.forEach((row, index) => {
      const visible = query ? row.dataset.name.includes(query) : this.expanded || index < this.visibleValue
      row.hidden = !visible
      if (visible) matches++
    })

    this.emptyTarget.hidden = matches > 0
    if (this.hasMoreTarget) {
      this.moreTarget.hidden = Boolean(query)
      this.moreTarget.textContent = this.expanded ? this.moreTarget.dataset.lessLabel : this.moreTarget.dataset.moreLabel
    }
  }

  normalize(value) {
    return value.normalize("NFD").replace(/[̀-ͯ]/g, "").trim().toLowerCase()
  }
}
