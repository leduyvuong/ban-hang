import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="layout-builder"
export default class extends Controller {
  static targets = [
    "input",
    "canvas",
    "componentList",
    "emptyState",
    "template"
  ]

  connect() {
    this.draggedElement = null
    this.dragSource = null
    this.isPublishing = false
    this.layoutConfig = this.parseLayoutConfig(this.inputTarget.value)
    this.refreshEmptyState()
    this.reconcileDomWithConfig()
  }

  startSidebarDrag(event) {
    const { componentType, componentDefaultConfig } = event.currentTarget.dataset
    event.dataTransfer.effectAllowed = "copy"
    this.dragSource = "library"
    event.dataTransfer.setData("text/plain", JSON.stringify({ source: "library", type: componentType, defaultConfig: componentDefaultConfig }))
    this.canvasTarget.classList.add("ring", "ring-blue-400", "ring-offset-2")
  }

  endSidebarDrag() {
    this.removeDropZoneHighlight()
    this.dragSource = null
  }

  startCanvasDrag(event) {
    const componentElement = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    this.dragSource = "canvas"
    event.dataTransfer.setData("text/plain", JSON.stringify({ source: "canvas", id: componentElement.dataset.componentId }))
    componentElement.classList.add("opacity-60")
    this.draggedElement = componentElement
  }

  endCanvasDrag(event) {
    event.currentTarget.classList.remove("opacity-60")
    this.canvasTarget.classList.remove("ring", "ring-blue-400", "ring-offset-2")
    this.dragSource = null
    this.draggedElement = null
  }

  allowDrop(event) {
    event.preventDefault()
    const dropEffect = this.dragSource === "library" ? "copy" : "move"
    try {
      event.dataTransfer.dropEffect = dropEffect
    } catch (error) {
      // Một số trình duyệt không cho phép thiết lập dropEffect, bỏ qua
    }
  }

  highlightDropZone() {
    this.canvasTarget.classList.add("ring", "ring-blue-400", "ring-offset-2")
  }

  removeDropZoneHighlight() {
    this.canvasTarget.classList.remove("ring", "ring-blue-400", "ring-offset-2")
  }

  handleDrop(event) {
    event.preventDefault()
    const data = this.safeParse(event.dataTransfer.getData("text/plain"))
    if (!data) return

    if (data.source === "library") {
      this.insertNewComponent(data, event)
    } else if (data.source === "canvas" && data.id) {
      this.reorderExistingComponent(data.id, event)
    }

    this.removeDropZoneHighlight()
    this.dragSource = null
    this.refreshEmptyState()
    this.recomputeOrders()
    this.persistConfig()
  }

  toggleComponentForm(event) {
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const form = componentElement.querySelector("[data-layout-builder-target='form']")
    if (!form) return

    form.classList.toggle("hidden")
  }

  removeComponent(event) {
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const componentId = componentElement.dataset.componentId
    componentElement.remove()
    this.layoutConfig.components = this.layoutConfig.components.filter((component) => component.id !== componentId)
    this.refreshEmptyState()
    this.recomputeOrders()
    this.persistConfig()
  }

  updateField(event) {
    const fieldName = event.currentTarget.dataset.fieldName
    const value = event.currentTarget.value
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const config = this.ensureConfig(componentElement)
    config.config[fieldName] = value
    this.updatePreview(componentElement, fieldName, value)
    this.persistConfig()
  }

  updateCollection(event) {
    const fieldName = event.currentTarget.dataset.fieldName
    const value = event.currentTarget.value
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const config = this.ensureConfig(componentElement)
    const values = value
      .split(",")
      .map((item) => item.trim())
      .filter((item) => item.length > 0)
    config.config[fieldName] = values
    this.updatePreview(componentElement, fieldName, values)
    this.persistConfig()
  }

  updateJsonCollection(event) {
    const fieldName = event.currentTarget.dataset.fieldName
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const config = this.ensureConfig(componentElement)

    try {
      const parsed = JSON.parse(event.currentTarget.value)
      if (!Array.isArray(parsed)) throw new Error("Không phải mảng")
      config.config[fieldName] = parsed
      event.currentTarget.classList.remove("border-red-400")
      this.updatePreview(componentElement, fieldName, parsed)
      this.persistConfig()
    } catch (error) {
      event.currentTarget.classList.add("border-red-400")
    }
  }

  saveDraft() {
    this.isPublishing = false
    this.persistConfig()
  }

  publish() {
    this.isPublishing = true
    this.persistConfig()
  }

  beforeSubmit() {
    this.persistConfig()
  }

  // Helpers

  reconcileDomWithConfig() {
    const knownIds = new Set(this.layoutConfig.components.map((component) => component.id))
    this.componentElements().forEach((element) => {
      if (!knownIds.has(element.dataset.componentId)) {
        const templateConfig = this.parseComponentConfig(element.dataset.componentConfig)
        this.layoutConfig.components.push({
          id: element.dataset.componentId,
          type: element.dataset.componentType,
          order: this.layoutConfig.components.length,
          config: templateConfig?.config || templateConfig || {}
        })
      }
    })
    this.recomputeOrders()
    this.persistConfig()
  }

  insertNewComponent(data, event) {
    const templateElement = this.templateTargets.find((template) => template.dataset.componentType === data.type)
    if (!templateElement) return

    const fragment = templateElement.content.cloneNode(true)
    const componentElement = fragment.firstElementChild
    if (!componentElement) return

    const newId = this.generateId()
    componentElement.dataset.componentId = newId
    const defaultConfig = this.parseComponentConfig(data.defaultConfig) || {}
    componentElement.dataset.componentConfig = JSON.stringify(defaultConfig)

    this.insertAtDropPosition(componentElement, event)

    this.layoutConfig.components.push({
      id: newId,
      type: componentElement.dataset.componentType,
      order: this.layoutConfig.components.length,
      config: JSON.parse(JSON.stringify(defaultConfig.config || defaultConfig))
    })

    this.persistConfig()
  }

  reorderExistingComponent(componentId, event) {
    const componentElement = this.componentElements().find((element) => element.dataset.componentId === componentId)
    if (!componentElement) return

    this.insertAtDropPosition(componentElement, event)
  }

  insertAtDropPosition(componentElement, event) {
    const reference = event.target.closest("[data-component-id]")
    if (!reference) {
      this.componentListTarget.appendChild(componentElement)
      return
    }

    const bounds = reference.getBoundingClientRect()
    const shouldInsertBefore = event.clientY < bounds.top + bounds.height / 2
    if (shouldInsertBefore) {
      this.componentListTarget.insertBefore(componentElement, reference)
    } else {
      this.componentListTarget.insertBefore(componentElement, reference.nextElementSibling)
    }
  }

  ensureConfig(componentElement) {
    const componentId = componentElement.dataset.componentId
    let componentConfig = this.layoutConfig.components.find((component) => component.id === componentId)
    if (!componentConfig) {
      componentConfig = {
        id: componentId,
        type: componentElement.dataset.componentType,
        order: this.layoutConfig.components.length,
        config: this.parseComponentConfig(componentElement.dataset.componentConfig) || {}
      }
      this.layoutConfig.components.push(componentConfig)
    }
    return componentConfig
  }

  updatePreview(componentElement, fieldName, value) {
    const previewContainer = componentElement.querySelector("[data-layout-builder-target='preview']")
    if (!previewContainer) return

    if (fieldName === "background_color") {
      previewContainer.querySelectorAll("[data-preview-field='background_color']").forEach((node) => {
        node.style.backgroundColor = value
      })
    } else if (fieldName === "text_color") {
      previewContainer.querySelectorAll("[data-preview-field-text-color]").forEach((node) => {
        node.style.color = value
      })
    } else if (fieldName === "image_url") {
      previewContainer.querySelectorAll("[data-preview-field='image_url']").forEach((node) => {
        node.style.backgroundImage = value ? `url(${value})` : "none"
      })
    } else if (Array.isArray(value)) {
      const target = previewContainer.querySelector(`[data-preview-field='${fieldName}']`)
      if (target) {
        target.dataset.count = value.length
        target.classList.add("ring-1", "ring-slate-200")
        target.textContent = `${value.length} mục được cấu hình`
      }
    } else {
      const target = previewContainer.querySelector(`[data-preview-field='${fieldName}']`)
      if (target) target.textContent = value
    }
  }

  componentElements() {
    return Array.from(this.componentListTarget.querySelectorAll("[data-component-id]"))
  }

  refreshEmptyState() {
    if (!this.hasEmptyStateTarget) return
    if (this.componentElements().length === 0) {
      this.emptyStateTarget.classList.remove("hidden")
    } else {
      this.emptyStateTarget.classList.add("hidden")
    }
  }

  recomputeOrders() {
    this.componentElements().forEach((element, index) => {
      element.dataset.componentOrder = index
      const config = this.ensureConfig(element)
      config.order = index
    })
    this.layoutConfig.components.sort((a, b) => a.order - b.order)
  }

  persistConfig() {
    this.inputTarget.value = JSON.stringify(this.layoutConfig)
  }

  parseLayoutConfig(value) {
    if (!value) return { components: [] }
    try {
      const parsed = typeof value === "string" ? JSON.parse(value) : value
      if (parsed && parsed.components) {
        parsed.components = parsed.components.map((component, index) => ({
          id: component.id || this.generateId(),
          type: component.type,
          order: component.order ?? index,
          config: component.config || {}
        }))
      }
      return parsed
    } catch (error) {
      console.warn("Không thể parse layout_config", error)
      return { components: [] }
    }
  }

  safeParse(value) {
    if (value === undefined || value === null) return null
    if (typeof value === "string") {
      try {
        return JSON.parse(value)
      } catch (error) {
        return null
      }
    }

    if (typeof value === "object") return value
    return null
  }

  parseComponentConfig(value) {
    const parsed = this.safeParse(value)
    if (!parsed) return {}
    return parsed.config ? parsed.config : parsed
  }

  generateId() {
    if (typeof window !== "undefined" && window.crypto && typeof window.crypto.randomUUID === "function") {
      return window.crypto.randomUUID()
    }

    return `component-${Date.now()}-${Math.floor(Math.random() * 1_000_000)}`
  }
}
