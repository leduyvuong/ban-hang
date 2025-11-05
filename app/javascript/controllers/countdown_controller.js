import { Controller } from "@hotwired/stimulus"

// Displays a live countdown for time-limited promotions.
export default class extends Controller {
  static targets = ["label"]
  static values = {
    targetTime: String,
    expiredText: { type: String, default: "Offer ended" }
  }

  connect() {
    if (!this.hasTargetTimeValue) return

    this.deadline = new Date(this.targetTimeValue)
    if (Number.isNaN(this.deadline.getTime())) return

    this.update()
    this.timer = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  update() {
    const now = new Date()
    const diffMs = this.deadline - now

    if (diffMs <= 0) {
      this.labelTarget.textContent = this.expiredTextValue
      clearInterval(this.timer)
      return
    }

    const totalSeconds = Math.floor(diffMs / 1000)
    const days = Math.floor(totalSeconds / 86400)
    const hours = Math.floor((totalSeconds % 86400) / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    const parts = []
    if (days > 0) parts.push(`${days}d`)
    if (hours > 0 || days > 0) parts.push(`${hours}h`)
    if (minutes > 0 || hours > 0 || days > 0) parts.push(`${minutes}m`)
    parts.push(`${seconds}s`)

    this.labelTarget.textContent = parts.join(" ")
  }
}
