import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-widget"
export default class extends Controller {
  static targets = ["panel", "frame", "badge"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
    this.frameLoaded = false
  }

  toggle(event) {
    event?.preventDefault()
    this.openValue ? this.close() : this.open()
  }

  open() {
    if (this.openValue) return

    this.openValue = true
    this.showPanel()
    this.loadFrame()
    this.hideBadge()
  }

  close(event) {
    event?.preventDefault()
    if (!this.openValue) return

    this.openValue = false
    this.hidePanel()
  }

  showPanel() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.remove("pointer-events-none", "translate-x-full", "opacity-0")
    this.panelTarget.classList.add("opacity-100")
  }

  hidePanel() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.add("pointer-events-none", "translate-x-full", "opacity-0")
    this.panelTarget.classList.remove("opacity-100")
  }

  loadFrame() {
    if (!this.hasFrameTarget || this.frameLoaded) return

    const src = this.frameTarget.dataset.chatWidgetSrc
    if (src && !this.frameTarget.getAttribute("src")) {
      this.frameTarget.setAttribute("src", src)
      this.frameLoaded = true
    }
  }

  hideBadge() {
    if (!this.hasBadgeTarget) return

    this.badgeTarget.classList.add("hidden")
  }
}
