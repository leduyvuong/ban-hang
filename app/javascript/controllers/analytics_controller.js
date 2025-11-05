import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "rangeSelect",
    "startDate",
    "endDate",
    "customFields",
    "loadingState",
    "content",
    "rangeLabel",
    "rangeWindow",
    "summaryValue",
    "trend",
    "revenueChart",
    "ordersChart",
    "customersChart",
    "topProducts",
    "currencyLabel"
  ]

  static values = {
    endpoint: String,
    initial: Object
  }

  connect() {
    this.charts = {}
    this.chartLoader = null
    this.currentData = null
    this.currentCurrency = null

    this.ensureChartJs().then(() => {
      this.applyData(this.initialValue)
      this.syncFormState(this.initialValue?.range)
    }).catch((error) => {
      console.error("Failed to load Chart.js", error)
    })
  }

  disconnect() {
    Object.values(this.charts).forEach((chart) => {
      if (chart?.destroy) chart.destroy()
    })
    this.charts = {}
  }

  preventSubmit(event) {
    event.preventDefault()
    if (this.rangeSelectTarget.value === "custom") {
      this.fetchMetrics({ range: "custom" })
    }
  }

  onFilterChange(event) {
    if (event.target === this.rangeSelectTarget) {
      const value = this.rangeSelectTarget.value
      if (value === "custom") {
        this.showCustomFields(true)
      } else {
        this.showCustomFields(false)
        this.fetchMetrics({ range: value })
      }
    }
  }

  fetchMetrics(params = {}) {
    if (!this.hasEndpointValue) return

    const search = new URLSearchParams(params)
    if (params.range === "custom") {
      if (this.startDateTarget.value) search.set("start_date", this.startDateTarget.value)
      if (this.endDateTarget.value) search.set("end_date", this.endDateTarget.value)
    }

    const url = `${this.endpointValue}?${search.toString()}`
    this.toggleLoading(true)

    fetch(url, { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data) => {
        this.ensureChartJs().then(() => {
          this.applyData(data)
          this.syncFormState(data.range)
        })
      })
      .catch((error) => {
        console.error("Analytics request failed", error)
      })
      .finally(() => this.toggleLoading(false))
  }

  applyData(payload) {
    if (!payload) return
    this.currentData = payload
    this.currentCurrency = (payload.currency || this.currentCurrency || "USD").toUpperCase()

    this.updateRangeInfo(payload.range)
    this.updateSummary(payload.summary)
    this.updateTopProducts(payload.top_products)
    this.renderChart("revenue", this.revenueChartTarget, payload.charts?.revenue, {
      borderColor: "#4f46e5",
      backgroundColor: "rgba(79,70,229,0.15)"
    })
    this.renderChart("orders", this.ordersChartTarget, payload.charts?.orders, {
      borderColor: "#0f766e",
      backgroundColor: "rgba(15,118,110,0.15)"
    })
    this.renderChart("customers", this.customersChartTarget, payload.charts?.customers, {
      borderColor: "#f97316",
      backgroundColor: "rgba(249,115,22,0.15)"
    })
  }

  updateRangeInfo(range) {
    if (!range) return
    if (this.hasRangeLabelTarget) this.rangeLabelTarget.textContent = range.label || ""

    if (this.hasRangeWindowTarget) {
      const formatter = new Intl.DateTimeFormat(undefined, {
        year: "numeric",
        month: "short",
        day: "numeric"
      })
      const start = range.start ? formatter.format(new Date(range.start)) : ""
      const end = range.end ? formatter.format(new Date(range.end)) : ""
      this.rangeWindowTarget.textContent = start && end ? `${start} — ${end}` : ""
    }

    if (this.hasCurrencyLabelTarget) {
      this.currencyLabelTarget.textContent = this.currentCurrency
    }
  }

  updateSummary(summary) {
    if (!summary) return

    this.summaryValueTargets.forEach((target) => {
      const key = target.dataset.key
      const format = target.dataset.format || "number"
      const value = this.resolve(summary, key)
      target.textContent = this.formatValue(value, format)
    })

    this.trendTargets.forEach((target) => {
      const key = target.dataset.key
      const format = target.dataset.format || "percent"
      const value = this.resolve(summary, key)
      target.textContent = this.formatTrend(value, format)
      target.classList.remove("text-emerald-600", "text-rose-600", "text-slate-500")
      if (value == null) {
        target.classList.add("text-slate-500")
      } else if (value > 0) {
        target.classList.add("text-emerald-600")
      } else if (value < 0) {
        target.classList.add("text-rose-600")
      } else {
        target.classList.add("text-slate-500")
      }
    })
  }

  updateTopProducts(products = []) {
    if (!this.hasTopProductsTarget) return
    const formatterCurrency = this.currencyFormatter()
    const formatterPercent = new Intl.NumberFormat(undefined, {
      style: "percent",
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    })

    this.topProductsTarget.innerHTML = ""

    if (products.length === 0) {
      const row = document.createElement("tr")
      const cell = document.createElement("td")
      cell.colSpan = 5
      cell.className = "px-4 py-4 text-center text-sm text-slate-500"
      cell.textContent = "No products in this period"
      row.appendChild(cell)
      this.topProductsTarget.appendChild(row)
      return
    }

    products.forEach((product) => {
      const row = document.createElement("tr")
      row.className = "hover:bg-slate-50/70"
      row.innerHTML = `
        <td class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-400">#${product.rank}</td>
        <td class="px-4 py-3 text-sm font-semibold text-slate-900">${product.product_name}</td>
        <td class="px-4 py-3 text-right text-sm text-slate-600">${this.formatValue(product.units_sold, "number")}</td>
        <td class="px-4 py-3 text-right text-sm font-semibold text-slate-900">${formatterCurrency.format(product.revenue || 0)}</td>
        <td class="px-4 py-3 text-right text-xs text-slate-500">${formatterPercent.format((product.revenue_share || 0) / 100)}</td>
      `
      this.topProductsTarget.appendChild(row)
    })
  }

  renderChart(key, canvas, config, colors) {
    if (!canvas || !config) return
    if (!window.Chart) return

    if (this.charts[key]) {
      this.charts[key].destroy()
      delete this.charts[key]
    }

    const context = canvas.getContext("2d")
    const currency = config.currency

    this.charts[key] = new window.Chart(context, {
      type: "line",
      data: {
        labels: config.labels || [],
        datasets: [
          {
            label: config.label,
            data: config.data || [],
            borderColor: colors.borderColor,
            backgroundColor: colors.backgroundColor,
            fill: true,
            tension: 0.35,
            pointRadius: 2,
            pointHoverRadius: 4,
            borderWidth: 2
          }
        ]
      },
      options: {
        maintainAspectRatio: false,
        responsive: true,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.parsed.y
                return currency ? this.formatValue(value, "currency") : this.formatValue(value, "number")
              }
            }
          }
        },
        scales: {
          y: {
            ticks: {
              callback: (value) => (currency ? this.formatValue(value, "currency") : this.formatValue(value, "number"))
            },
            grid: { color: "rgba(148, 163, 184, 0.2)" }
          },
          x: {
            grid: { display: false }
          }
        }
      }
    })
  }

  toggleLoading(state) {
    if (!this.hasLoadingStateTarget) return
    this.loadingStateTarget.classList.toggle("hidden", !state)
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("opacity-50", state)
    }
  }

  ensureChartJs() {
    if (window.Chart) return Promise.resolve()
    if (this.chartLoader) return this.chartLoader

    this.chartLoader = new Promise((resolve, reject) => {
    const script = document.createElement("script")
      script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"
      script.async = true
      script.onload = () => resolve()
      script.onerror = (error) => reject(error)
      document.head.appendChild(script)
    })

    return this.chartLoader
  }

  showCustomFields(visible) {
    if (!this.hasCustomFieldsTarget) return
    this.customFieldsTarget.classList.toggle("hidden", !visible)
    if (visible) {
      this.customFieldsTarget.classList.add("flex")
    } else {
      this.customFieldsTarget.classList.remove("flex")
    }
  }

  syncFormState(range) {
    if (!range) return
    if (this.hasRangeSelectTarget) {
      this.rangeSelectTarget.value = range.preset || "last_30_days"
    }

    const isCustom = range.preset === "custom"
    this.showCustomFields(isCustom)

    if (isCustom) {
      if (this.hasStartDateTarget && range.start) {
        this.startDateTarget.value = this.isoToDate(range.start)
      }
      if (this.hasEndDateTarget && range.end) {
        this.endDateTarget.value = this.isoToDate(range.end)
      }
    } else {
      if (this.hasStartDateTarget) this.startDateTarget.value = ""
      if (this.hasEndDateTarget) this.endDateTarget.value = ""
    }
  }

  isoToDate(value) {
    if (!value) return ""
    const date = new Date(value)
    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, "0")
    const day = `${date.getDate()}`.padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  resolve(object, path) {
    if (!object || !path) return undefined
    return path.split(".").reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), object)
  }

  formatValue(raw, format) {
    if (raw == null) {
      return format === "percent-or-na" ? "N/A" : "—"
    }

    switch (format) {
      case "currency":
        return this.currencyFormatter().format(Number(raw))
      case "percent":
        return `${Number(raw).toFixed(2)}%`
      case "percent-or-na":
        return `${Number(raw).toFixed(2)}%`
      case "number":
      default:
        return new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(Number(raw))
    }
  }

  formatTrend(value, format) {
    if (value == null) return "No change"
    const absolute = Math.abs(Number(value)).toFixed(2)
    if (value > 0) return `▲ ${absolute}% vs last month`
    if (value < 0) return `▼ ${absolute}% vs last month`
    return "No change"
  }

  currencyFormatter() {
    const code = (this.currentCurrency || "USD").toUpperCase()
    const precision = code === "VND" ? 0 : 2
    const formatter = new Intl.NumberFormat(undefined, {
      minimumFractionDigits: precision,
      maximumFractionDigits: precision
    })
    const symbol = CURRENCY_SYMBOLS[code] || code

    return {
      format: (value) => `${symbol} ${formatter.format(Number(value))}`
    }
  }
}
const CURRENCY_SYMBOLS = {
  USD: "🌐 USD",
  EUR: "€",
  VND: "₫"
}
