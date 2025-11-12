import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.2 },
    once: { type: Boolean, default: true }
  }

  connect() {
    this.revealed = false
    this.element.classList.add("opacity-0", "translate-y-6", "transition-all", "duration-700", "ease-out")

    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      threshold: this.thresholdValue
    })

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        this.reveal()
        if (this.onceValue && this.observer) {
          this.observer.unobserve(this.element)
        }
      }
    })
  }

  reveal() {
    if (this.revealed) return

    this.revealed = true
    this.element.classList.remove("opacity-0", "translate-y-6")
    this.element.classList.add("opacity-100", "translate-y-0")
  }
}
