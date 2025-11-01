import { Controller } from "@hotwired/stimulus"

// Handles fetching the AJAX modal and managing show/hide transitions.
export default class extends Controller {
  static targets = ["container", "panel", "overlay", "backdrop"]
  static values = {
    url: String
  }

  connect() {
    this.loading = false
  }

  async open(event) {
    event.preventDefault()
    if (this.loading || !this.hasUrlValue || !this.hasContainerTarget) return

    this.loading = true

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin"
      })

      if (!response.ok) throw new Error(`Modal request failed with ${response.status}`)

      const html = await response.text()
      await this.#injectModal(html)
      this.#lockScroll()
      this.#focusPanel()
      this.#listenForKeydown()
    } catch (error) {
      console.error(error)
      this.containerTarget.innerHTML = ""
      this.#unlockScroll()
    } finally {
      this.loading = false
    }
  }

  close(event) {
    if (event) event.preventDefault()
    if (!this.hasContainerTarget) return

    this.containerTarget.innerHTML = ""
    this.#unlockScroll()
    this.#removeKeydownListener()
  }

  disconnect() {
    this.#removeKeydownListener()
    this.#unlockScroll()
  }

  #focusPanel() {
    if (this.hasPanelTarget) {
      this.panelTarget.setAttribute("tabindex", "-1")
      this.panelTarget.focus({ preventScroll: true })
    }
  }

  async #injectModal(html) {
    this.containerTarget.innerHTML = html
    await this.#nextFrame()
  }

  #lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  #unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }

  #listenForKeydown() {
    this.#removeKeydownListener()
    this.boundKeydownHandler = (event) => {
      if (event.key === "Escape") this.close(event)
    }
    document.addEventListener("keydown", this.boundKeydownHandler)
  }

  #removeKeydownListener() {
    if (this.boundKeydownHandler) {
      document.removeEventListener("keydown", this.boundKeydownHandler)
      this.boundKeydownHandler = null
    }
  }

  #nextFrame() {
    return new Promise((resolve) => requestAnimationFrame(resolve))
  }
}
