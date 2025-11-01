import { Controller } from "@hotwired/stimulus"

// Handles toggling of the admin sidebar on smaller viewports.
export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    document.body.classList.toggle("admin-sidebar-open")
  }
}
