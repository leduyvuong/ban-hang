import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    step: Number,
    orderComplete: Boolean
  }

  connect() {
    this.updateUrl()
  }

  updateUrl() {
    const step = this.stepValue || 1
    const params = new URLSearchParams(window.location.search)

    if (step <= 1) {
      params.delete("step")
    } else {
      params.set("step", String(step))
    }

    if (this.orderCompleteValue) {
      params.set("complete", "true")
    } else {
      params.delete("complete")
    }

    const search = params.toString()
    const newUrl = `${window.location.pathname}${search ? `?${search}` : ""}`
    const currentUrl = `${window.location.pathname}${window.location.search}`

    if (newUrl !== currentUrl) {
      history.replaceState({}, "", newUrl)
    }
  }
}
