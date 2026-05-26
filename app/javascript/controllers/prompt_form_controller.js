import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]

  connect() {
    this.updateCount()
  }

  useExample(event) {
    this.inputTarget.value = event.params.prompt
    this.inputTarget.focus()
    this.updateCount()
  }

  updateCount() {
    if (!this.hasCountTarget) return

    const remaining = Math.max(40 - this.inputTarget.value.trim().length, 0)
    this.countTarget.textContent = remaining === 0 ? "Ready to analyze" : `${remaining} more needed`
  }
}
