import { Controller } from "@hotwired/stimulus"

// Auto-dismiss flash alerts after a configurable timeout.
export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 5000 }
  }

  connect() {
    this.timeoutId = window.setTimeout(() => this.dismiss(), this.timeoutValue)
  }

  disconnect() {
    if (this.timeoutId) {
      window.clearTimeout(this.timeoutId)
    }
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-x-2")
    window.setTimeout(() => {
      this.element.remove()
    }, 250)
  }
}
