import { Controller } from "@hotwired/stimulus"

// Automatically subscribe to new conversations when they're added to the DOM
export default class extends Controller {
  static values = {
    streamName: String
  }

  connect() {
    if (this.hasStreamNameValue) {
      this.subscribe()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.remove()
    }
  }

  subscribe() {
    // Create a turbo-cable-stream-source element to subscribe
    const source = document.createElement('turbo-cable-stream-source')
    source.setAttribute('channel', 'Turbo::StreamsChannel')
    source.setAttribute('signed-stream-name', this.streamNameValue)
    
    // Append to body (Turbo will automatically handle it)
    document.body.appendChild(source)
    this.subscription = source
  }
}
