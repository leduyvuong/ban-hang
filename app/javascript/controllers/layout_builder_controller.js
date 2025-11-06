import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="layout-builder"
export default class extends Controller {
  static targets = [
    "input",
    "canvas",
    "componentList",
    "emptyState",
    "template",
    "dropzone"
  ]

  connect() {
    this.draggedElement = null
    this.dragSource = null
    this.isPublishing = false
    this.layoutConfig = this.parseLayoutConfig(this.inputTarget.value)
    this.refreshEmptyState()
    this.syncState()
  }

  startSidebarDrag(event) {
    const { componentType, componentDefaultConfig } = event.currentTarget.dataset
    event.dataTransfer.effectAllowed = "copy"
    this.dragSource = "library"
    event.dataTransfer.setData(
      "text/plain",
      JSON.stringify({ source: "library", type: componentType, defaultConfig: componentDefaultConfig })
    )
    this.highlightAllDropZones()
  }

  endSidebarDrag() {
    this.clearDropZoneHighlights()
    this.dragSource = null
  }

  startCanvasDrag(event) {
    const componentElement = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    this.dragSource = "canvas"
    event.dataTransfer.setData(
      "text/plain",
      JSON.stringify({ source: "canvas", id: componentElement.dataset.componentId })
    )
    componentElement.classList.add("opacity-60")
    this.draggedElement = componentElement
    this.highlightAllDropZones()
  }

  endCanvasDrag(event) {
    event.currentTarget.classList.remove("opacity-60")
    this.dragSource = null
    this.draggedElement = null
    this.clearDropZoneHighlights()
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

  highlightDropZone(event) {
    if (event?.currentTarget) {
      event.currentTarget.classList.add("ring", "ring-blue-400", "ring-offset-2")
    }
  }

  removeDropZoneHighlight(event) {
    if (event?.currentTarget && event.relatedTarget && event.currentTarget.contains(event.relatedTarget)) {
      return
    }
    if (event?.currentTarget) {
      event.currentTarget.classList.remove("ring", "ring-blue-400", "ring-offset-2")
    }
  }

  handleDrop(event) {
    event.preventDefault()
    const dropZone = event.currentTarget
    const data = this.safeParse(event.dataTransfer.getData("text/plain"))
    if (!data) return

    if (data.source === "library") {
      this.insertNewComponent(data, event, dropZone)
    } else if (data.source === "canvas" && data.id) {
      this.reorderExistingComponent(data.id, event, dropZone)
    }

    this.clearDropZoneHighlights()
    this.dragSource = null
    this.refreshEmptyState()
    this.syncState()
  }

  toggleComponentForm(event) {
    const componentElement = event.currentTarget.closest("[data-component-id]")
    const form = componentElement?.querySelector("[data-layout-builder-target='form']")
    if (!form) return

    form.classList.toggle("hidden")
  }

  removeComponent(event) {
    const componentElement = event.currentTarget.closest("[data-component-id]")
    if (!componentElement) return

    componentElement.remove()
    this.refreshEmptyState()
    this.syncState()
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
    this.syncState()
  }

  publish() {
    this.isPublishing = true
    this.syncState()
  }

  beforeSubmit() {
    this.syncState()
  }

  // Helpers

  insertNewComponent(data, event, dropZone) {
    const templateElement = this.templateTargets.find((template) => template.dataset.componentType === data.type)
    if (!templateElement) return

    const fragment = templateElement.content.cloneNode(true)
    const componentElement = fragment.firstElementChild
    if (!componentElement) return

    const newId = this.generateId()
    componentElement.dataset.componentId = newId
    const defaultConfig = this.parseComponentConfig(data.defaultConfig) || {}
    componentElement.dataset.componentConfig = JSON.stringify(defaultConfig)

    this.insertAtDropPosition(componentElement, event, dropZone)
    this.updateComponentInternalReferences(componentElement, newId)
  }

  reorderExistingComponent(componentId, event, dropZone) {
    const componentElement = this.componentElementById(componentId)
    if (!componentElement) return

    this.insertAtDropPosition(componentElement, event, dropZone)
  }

  insertAtDropPosition(componentElement, event, dropZone) {
    const reference = event.target.closest("[data-component-id]")
    if (!reference || !dropZone.contains(reference)) {
      dropZone.appendChild(componentElement)
      return
    }

    const bounds = reference.getBoundingClientRect()
    const shouldInsertBefore = event.clientY < bounds.top + bounds.height / 2
    if (shouldInsertBefore) {
      dropZone.insertBefore(componentElement, reference)
    } else {
      dropZone.insertBefore(componentElement, reference.nextElementSibling)
    }
  }

  ensureConfig(componentElement) {
    if (!componentElement) return {}
    const componentId = componentElement.dataset.componentId
    let componentConfig = this.findComponentById(componentId)
    if (!componentConfig) {
      const parentZone = componentElement.parentElement?.closest("[data-dropzone-parent-id]")
      const parentId = parentZone?.dataset.dropzoneParentId || "root"
      const slot = parentZone?.dataset.dropzoneSlot || "root"
      if (parentId !== "root") {
        const parentElement = componentElement.parentElement?.closest("[data-component-id]")
        if (parentElement) this.ensureConfig(parentElement)
      }
      componentConfig = {
        id: componentId,
        type: componentElement.dataset.componentType,
        order: 0,
        config: this.parseComponentConfig(componentElement.dataset.componentConfig) || {},
        children: this.initialChildrenFromDataset(componentElement)
      }
      const targetCollection = this.findParentCollection(parentId, slot)
      targetCollection.push(componentConfig)
    }
    if (!componentConfig.children) {
      componentConfig.children = this.initialChildrenFromDataset(componentElement)
    }
    return componentConfig
  }

  updatePreview(componentElement, fieldName, value) {
    const previewContainer = componentElement?.querySelector("[data-layout-builder-target='preview']")
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
    return Array.from(this.element.querySelectorAll("[data-component-id]"))
  }

  componentElementById(id) {
    return this.element.querySelector(`[data-component-id='${CSS.escape(id)}']`)
  }

  refreshEmptyState() {
    if (!this.hasEmptyStateTarget) return
    const hasRootComponents = Array.from(this.componentListTarget.children).some(
      (child) => child.dataset && child.dataset.componentId
    )
    if (!hasRootComponents) {
      this.emptyStateTarget.classList.remove("hidden")
    } else {
      this.emptyStateTarget.classList.add("hidden")
    }
  }

  syncState() {
    this.componentElements().forEach((element) => this.ensureConfig(element))

    const zones = [...this.dropzoneTargets]
    zones.sort((a, b) => {
      if ((a.dataset.dropzoneParentId || "root") === "root") return -1
      if ((b.dataset.dropzoneParentId || "root") === "root") return 1
      return 0
    })

    zones.forEach((dropZone) => {
      const parentId = dropZone.dataset.dropzoneParentId || "root"
      const slot = dropZone.dataset.dropzoneSlot || "root"
      const childElements = Array.from(dropZone.children).filter(
        (child) => child.dataset && child.dataset.componentId
      )
      const collection = this.findParentCollection(parentId, slot)
      collection.splice(0, collection.length)
      childElements.forEach((childElement, index) => {
        const config = this.findComponentById(childElement.dataset.componentId)
        if (config) {
          config.order = index
          collection.push(config)
        }
      })
    })

    this.layoutConfig.components.sort((a, b) => a.order - b.order)
    this.persistConfig()
    this.updateDropzonePlaceholders()
  }

  persistConfig() {
    this.inputTarget.value = JSON.stringify(this.layoutConfig)
  }

  parseLayoutConfig(value) {
    if (!value) return { components: [] }
    try {
      const parsed = typeof value === "string" ? JSON.parse(value) : value
      if (parsed && parsed.components) {
        parsed.components = parsed.components.map((component, index) => this.normalizeComponent(component, index))
      }
      return parsed || { components: [] }
    } catch (error) {
      console.warn("Không thể parse layout_config", error)
      return { components: [] }
    }
  }

  normalizeComponent(component, index = 0) {
    const normalized = {
      id: component.id || this.generateId(),
      type: component.type,
      order: component.order ?? index,
      config: component.config || {},
      children: {}
    }

    const children = component.children || {}
    Object.keys(children).forEach((slot) => {
      const slotChildren = Array.isArray(children[slot]) ? children[slot] : []
      normalized.children[slot] = slotChildren.map((child, childIndex) => this.normalizeComponent(child, childIndex))
    })

    return normalized
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

  highlightAllDropZones() {
    if (this.hasCanvasTarget) {
      this.canvasTarget.classList.add("ring", "ring-blue-400", "ring-offset-2")
    }
  }

  clearDropZoneHighlights() {
    if (this.hasCanvasTarget) {
      this.canvasTarget.classList.remove("ring", "ring-blue-400", "ring-offset-2")
    }
    this.dropzoneTargets.forEach((zone) => {
      zone.classList.remove("ring", "ring-blue-400", "ring-offset-2")
    })
  }

  findComponentById(id, collection = this.layoutConfig.components) {
    for (const component of collection) {
      if (component.id === id) return component
      const children = component.children || {}
      for (const slot of Object.keys(children)) {
        const found = this.findComponentById(id, children[slot])
        if (found) return found
      }
    }
    return null
  }

  findParentCollection(parentId, slot) {
    if (parentId === "root") {
      return this.layoutConfig.components
    }
    const parentComponent = this.findComponentById(parentId)
    if (!parentComponent) return []
    if (!parentComponent.children) parentComponent.children = {}
    if (!parentComponent.children[slot]) parentComponent.children[slot] = []
    return parentComponent.children[slot]
  }

  initialChildrenFromDataset(componentElement) {
    const areas = this.safeParse(componentElement.dataset.componentAreas)
    if (!areas || !Array.isArray(areas)) return {}
    return areas.reduce((memo, area) => {
      memo[area.key || area["key"]] = []
      return memo
    }, {})
  }

  updateComponentInternalReferences(componentElement, newId) {
    componentElement.querySelectorAll("[data-dropzone-parent-id]").forEach((zone) => {
      if (zone.dataset.dropzoneParentId === "__COMPONENT_ID__") {
        zone.dataset.dropzoneParentId = newId
      }
    })
  }

  updateDropzonePlaceholders() {
    this.dropzoneTargets.forEach((dropZone) => {
      const placeholder = dropZone.querySelector("[data-slot-placeholder]")
      if (!placeholder) return
      const hasComponents = Array.from(dropZone.children).some(
        (child) => child.dataset && child.dataset.componentId
      )
      if (hasComponents) {
        placeholder.classList.add("hidden")
      } else {
        placeholder.classList.remove("hidden")
      }
    })
  }
}
