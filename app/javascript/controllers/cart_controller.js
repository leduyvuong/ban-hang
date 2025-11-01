import { Controller } from "@hotwired/stimulus"

// Handles cart interactions across the site, including the mini-cart and full cart page.
export default class extends Controller {
  static targets = ["mini", "drawer", "count", "fullItems", "fullSummary", "notifications"]
  static values = {
    addUrl: String,
    updateUrl: String,
    removeUrl: String,
    clearUrl: String,
    miniUrl: String
  }

  connect() {
    console.log("🛒 Cart controller connected!")
    console.log("URL values:", {
      addUrl: this.addUrlValue,
      updateUrl: this.updateUrlValue,
      removeUrl: this.removeUrlValue,
      clearUrl: this.clearUrlValue,
      miniUrl: this.miniUrlValue
    })
    
    // Test alert để đảm bảo JavaScript hoạt động
    setTimeout(() => {
      console.log("🎯 Cart controller is working!")
    }, 1000)
    
    this.drawerOpen = false
    this.csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    this.boundKeydownHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.removeKeydownListener()
  }

  toggleDrawer(event) {
    if (!this.shouldHandle(event)) return
    event.preventDefault()
    this.toggleTrigger = event.currentTarget

    if (this.drawerOpen) {
      this.closeDrawer()
    } else {
      this.openDrawer()
    }
  }

  test() {
    console.log("🧪 Test method called!")
    alert("Stimulus is working!")
  }

  async addItem(event) {
    console.log("🛍️ Add item called", event)
    if (!this.shouldHandle(event)) return
    event.preventDefault()
    const productId = this.paramOrData(event, "productId")
    console.log("Product ID:", productId)
    console.log("Add URL:", this.addUrlValue)
    if (!productId) {
      this.showMessage("Unable to add product to cart.")
      return
    }
    const quantity = parseInt(this.paramOrData(event, "quantity") || "1", 10)
    console.log("Quantity:", quantity)

    const data = await this.request(this.addUrlValue, "POST", {
      product_id: productId,
      quantity: quantity
    })
    console.log("Request result:", data)
  }

  async incrementItem(event) {
    if (!this.shouldHandle(event)) return
    event.preventDefault()
    const { productId } = event.params
    const input = this.findQuantityInputFrom(event.currentTarget)
    const current = parseInt(input?.value || "1", 10)
    await this.request(this.updateUrlValue, "PATCH", {
      product_id: productId,
      quantity: current + 1
    })
  }

  async decrementItem(event) {
    if (!this.shouldHandle(event)) return
    event.preventDefault()
    const { productId } = event.params
    const input = this.findQuantityInputFrom(event.currentTarget)
    const current = parseInt(input?.value || "1", 10)
    const nextQuantity = Math.max(current - 1, 0)
    await this.request(this.updateUrlValue, "PATCH", {
      product_id: productId,
      quantity: nextQuantity
    })
  }

  async updateQuantity(event) {
    const { productId } = event.params
    const nextQuantity = Math.max(parseInt(event.currentTarget.value || "1", 10), 1)
    event.currentTarget.value = nextQuantity

    await this.request(this.updateUrlValue, "PATCH", {
      product_id: productId,
      quantity: nextQuantity
    })
  }

  async removeItem(event) {
    if (!this.shouldHandle(event)) return
    event.preventDefault()
    const { productId } = event.params

    await this.request(this.removeUrlValue, "DELETE", {
      product_id: productId
    })
  }

  async clearCart(event) {
    if (!this.shouldHandle(event)) return
    event.preventDefault()

    await this.request(this.clearUrlValue, "DELETE")
  }

  openDrawer() {
    if (!this.hasDrawerTarget) return

    if (!this.drawerOpen && this.hasMiniUrlValue) {
      this.request(this.miniUrlValue, "GET")
    }

    this.drawerTarget.classList.remove("hidden")
    this.drawerOpen = true
    this.addKeydownListener()
    this.setToggleExpanded(true)
  }

  closeDrawer(event) {
    if (event) event.preventDefault()
    if (!this.hasDrawerTarget) return

    this.drawerTarget.classList.add("hidden")
    this.drawerOpen = false
    this.removeKeydownListener()
    this.setToggleExpanded(false)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeDrawer()
    }
  }

  addKeydownListener() {
    document.addEventListener("keydown", this.boundKeydownHandler)
  }

  removeKeydownListener() {
    document.removeEventListener("keydown", this.boundKeydownHandler)
  }

  shouldHandle(event) {
    console.log("Should handle check:", {
      event: event,
      defaultPrevented: event?.defaultPrevented,
      type: event?.type,
      button: event?.button,
      metaKey: event?.metaKey,
      ctrlKey: event?.ctrlKey,
      shiftKey: event?.shiftKey,
      altKey: event?.altKey
    })
    if (!event) return true
    if (event.defaultPrevented) return false
    if (event.type === "click" && event.button !== 0) return false
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false
    return true
  }

  findQuantityInputFrom(element) {
    const wrapper = element.closest("div")
    if (!wrapper) return null
    return wrapper.querySelector('input[type="number"]')
  }

  async request(url, method, payload = null) {
    if (!url) return null

    const isMutation = method !== "GET"
    if (isMutation && this.loading) return null
    if (isMutation) this.loading = true

    const body = payload ? JSON.stringify(payload) : null

    try {
      const response = await fetch(url, {
        method,
        headers: this.headers(method),
        body
      })

      if (!response.ok) {
        this.handleError(response)
        return null
      }

      const data = await response.json()
      this.applyUpdate(data)
      return data
    } catch (error) {
      console.error(error)
      this.showMessage("Something went wrong while updating your cart.")
      return null
    } finally {
      if (isMutation) this.loading = false
    }
  }

  applyUpdate(data) {
    if (!data) return

    if (this.hasMiniTarget && data.mini) {
      this.updateTarget(this.miniTarget, data.mini)
    }

    if (this.hasDrawerTarget && data.drawer) {
      this.updateTarget(this.drawerTarget, data.drawer)
      if (this.drawerOpen) {
        this.drawerTarget.classList.remove("hidden")
      }
    }

    if (this.hasFullItemsTarget && data.full_items) {
      this.updateTarget(this.fullItemsTarget, data.full_items)
    }

    if (this.hasFullSummaryTarget && data.summary) {
      this.updateTarget(this.fullSummaryTarget, data.summary)
    }

    if (data.message) {
      this.showMessage(data.message)
    }
  }

  updateTarget(target, html) {
    if (!target) return
    target.innerHTML = html
  }

  setToggleExpanded(value) {
    if (!this.toggleTrigger) return
    this.toggleTrigger.setAttribute("aria-expanded", value ? "true" : "false")
  }

  headers(method = "GET") {
    const headers = {
      Accept: "application/json"
    }

    if (method !== "GET") {
      headers["Content-Type"] = "application/json"
    }

    if (this.csrfToken) {
      headers["X-CSRF-Token"] = this.csrfToken
    }

    return headers
  }

  showMessage(message) {
    if (!message || !this.hasNotificationsTarget) return

    const toast = document.createElement("div")
    toast.className = "pointer-events-auto rounded-2xl border border-indigo-100 bg-white px-4 py-3 text-sm text-gray-700 shadow-lg transition transform opacity-0 translate-y-2"
    toast.textContent = message

    this.notificationsTarget.appendChild(toast)

    requestAnimationFrame(() => {
      toast.classList.remove("opacity-0", "translate-y-2")
    })

    setTimeout(() => {
      toast.classList.add("opacity-0", "translate-y-2")
    }, 2800)

    setTimeout(() => {
      toast.remove()
    }, 3300)
  }

  async handleError(response) {
    let message = `Cart request failed (${response.status})`
    try {
      const data = await response.json()
      if (data?.message) {
        message = data.message
      }
    } catch (error) {
      // Response not JSON, ignore
    }

    console.error(message)
    this.showMessage(message)
  }

  paramOrData(event, name) {
    const params = event.params || {}
    if (params[name] !== undefined) return params[name]

    const dataset = event.currentTarget?.dataset || {}
    const camelName = this.camelCase(name)
    if (dataset[camelName] !== undefined) return dataset[camelName]

    const cartPrefixed = dataset[`cart${camelName.charAt(0).toUpperCase()}${camelName.slice(1)}Param`]
    if (cartPrefixed !== undefined) return cartPrefixed

    const dataAttr = dataset[`cart${camelName.charAt(0).toUpperCase()}${camelName.slice(1)}`]
    return dataAttr
  }

  camelCase(value) {
    return value.replace(/-([a-z])/g, (_, char) => char.toUpperCase())
  }
}
