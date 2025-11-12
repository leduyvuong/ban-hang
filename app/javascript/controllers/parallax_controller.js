import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parallax"
export default class extends Controller {
  static targets = ["background"]
  static values = {
    speed: { type: Number, default: 0.3 }
  }

  connect() {
    this.isTicking = false
    this.handleScroll = this.handleScroll.bind(this)
    this.update()
    window.addEventListener("scroll", this.handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    if (this.isTicking) return

    this.isTicking = true
    requestAnimationFrame(() => {
      this.update()
      this.isTicking = false
    })
  }

  update() {
    const offset = window.scrollY * this.speedValue

    this.backgroundTargets.forEach((element) => {
      element.style.transform = `translate3d(0, ${offset * -1}px, 0)`
    })
  }
}
