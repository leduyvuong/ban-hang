import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="scroll"
export default class extends Controller {
  connect() {
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.element, { childList: true, subtree: true });
    this.scrollToBottom();
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight;
    });
  }
}
