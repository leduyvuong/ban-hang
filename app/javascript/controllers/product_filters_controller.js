import { Controller } from "@hotwired/stimulus"

// Coordinates AJAX-powered product filtering, sorting, and pagination.
// Keeps the URL in sync, shows a loading skeleton, and debounces search input.
export default class extends Controller {
  static targets = ["form", "frame", "skeleton", "page"]
  static values = {
    debounce: { type: Number, default: 250 }
  }

  connect() {
    this.searchTimeout = null
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  submit(event) {
    if (event) event.preventDefault()
    this.resetPage()
    this.requestSubmit()
  }

  debouncedSearch(event) {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    this.searchTimeout = setTimeout(() => {
      this.resetPage()
      this.requestSubmit()
    }, this.debounceValue)
  }

  handleSubmitStart() {
    this.showSkeleton()
  }

  handleSubmitEnd(event) {
    if (!event.detail.success) {
      this.hideSkeleton()
    }
  }

  handleBeforeFetchRequest() {
    this.showSkeleton()
  }

  handleFrameLoad(event) {
    this.hideSkeleton()

    const url = event.detail?.fetchResponse?.response?.url
    if (url) {
      window.history.pushState({}, "", url)
    }
  }

  clearFilters(event) {
    event.preventDefault()

    if (!this.hasFormTarget) return

    this.formTarget.reset()
    this.resetPage()
    this.requestSubmit()
  }

  requestSubmit() {
    if (!this.hasFormTarget) return

    if (typeof this.formTarget.requestSubmit === "function") {
      this.formTarget.requestSubmit()
    } else {
      this.formTarget.submit()
    }
  }

  resetPage() {
    if (this.hasPageTarget) {
      this.pageTarget.value = ""
    }
  }

  showSkeleton() {
    if (!this.hasSkeletonTarget) return

    this.skeletonTarget.classList.remove("hidden")
  }

  hideSkeleton() {
    if (!this.hasSkeletonTarget) return

    this.skeletonTarget.classList.add("hidden")
  }
}
