import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["panel", "button", "openIcon", "closeIcon"]

  connect() {
    this.open = false
    this.resizeHandler = this.closeOnResize.bind(this)
    this.keydownHandler = this.handleKeydown.bind(this)
    window.addEventListener("resize", this.resizeHandler)
    window.addEventListener("keydown", this.keydownHandler)

    if (this.hasPanelTarget) {
      this.panelTarget.hidden = true
      this.panelTarget.classList.remove("opacity-100")
      this.panelTarget.classList.add("opacity-0", "pointer-events-none", "transition", "duration-300", "ease-out")
    }

    this.updateAria()
  }

  disconnect() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
    }
    window.removeEventListener("resize", this.resizeHandler)
    window.removeEventListener("keydown", this.keydownHandler)
  }

  toggle(event) {
    event.preventDefault()
    this.open = !this.open
    this.updatePanel()
    this.updateIcons()
    this.updateAria()
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  close() {
    if (!this.open) return

    this.open = false
    this.updatePanel()
    this.updateIcons()
    this.updateAria()
  }

  closeOnResize() {
    if (window.innerWidth >= 1024) {
      this.close()
    }
  }

  updatePanel() {
    if (!this.hasPanelTarget) return

    if (this.open) {
      if (this.hideTimeout) {
        clearTimeout(this.hideTimeout)
      }
      this.panelTarget.hidden = false
      this.panelTarget.classList.remove("opacity-0", "pointer-events-none")
      this.panelTarget.classList.add("opacity-100")
    } else {
      this.panelTarget.classList.remove("opacity-100")
      this.panelTarget.classList.add("opacity-0", "pointer-events-none")
      this.hideTimeout = setTimeout(() => {
        this.panelTarget.hidden = true
        this.hideTimeout = null
      }, 200)
    }
  }

  updateIcons() {
    if (!this.hasOpenIconTarget || !this.hasCloseIconTarget) return

    this.openIconTarget.classList.toggle("hidden", this.open)
    this.closeIconTarget.classList.toggle("hidden", !this.open)
  }

  updateAria() {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", this.open.toString())
    }
  }
}
