import { Controller } from "@hotwired/stimulus"

// Handles progressive enhancement for the product listing filters.
// The form still works without JavaScript, but with this controller
// it submits via Turbo to refresh only the product grid and keeps the URL in sync.
export default class extends Controller {
  connect() {
    this.submitEndHandler = this.updateHistory.bind(this)
    this.element.addEventListener("turbo:submit-end", this.submitEndHandler)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.submitEndHandler)
  }

  submit() {
    if (typeof this.element.requestSubmit === "function") {
      this.element.requestSubmit()
    } else {
      this.element.submit()
    }
  }

  updateHistory(event) {
    if (!event.detail || !event.detail.success) return

    const fetchResponse = event.detail.fetchResponse
    if (!fetchResponse) return

    const url = fetchResponse.response.url
    if (url) {
      window.history.replaceState({}, "", url)
    }
  }
}
