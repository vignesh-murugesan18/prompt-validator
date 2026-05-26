import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result"]
  static values = {
    interval: { type: Number, default: 2500 },
    url: String
  }

  connect() {
    this.poll()
  }

  disconnect() {
    this.stop()
  }

  poll() {
    if (!this.hasUrlValue || this.isFinished()) return

    this.timer = setTimeout(async () => {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/html" }
      })

      if (response.ok) {
        const html = await response.text()
        const template = document.createElement("template")
        template.innerHTML = html.trim()

        this.resultTarget.innerHTML = html
        this.resultTarget.dataset.status = template.content.firstElementChild?.dataset.status || this.resultTarget.dataset.status
      }

      this.poll()
    }, this.intervalValue)
  }

  stop() {
    if (this.timer) clearTimeout(this.timer)
  }

  isFinished() {
    return ["completed", "failed"].includes(this.resultTarget.dataset.status)
  }
}
