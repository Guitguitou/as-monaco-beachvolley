import { Controller } from "@hotwired/stimulus"

// Turns a <select multiple> into a Tom Select searchable multi-select
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Rechercher..." },
    create: { type: Boolean, default: false },
  }

  connect() {
    if (!window.TomSelect) return
    const options = {
      plugins: ['remove_button'],
      placeholder: this.placeholderValue,
      create: this.createValue,
      persist: false,
      allowEmptyOption: true,
      render: {
        option: (data, escape) => `<div>${escape(data.text)}</div>`,
        item: (data, escape) => `<div>${escape(data.text)}</div>`,
      },
    }
    this.ts = new TomSelect(this.element, options)
  }

  disconnect() {
    if (this.ts) {
      this.ts.destroy()
      this.ts = null
    }
  }
}
