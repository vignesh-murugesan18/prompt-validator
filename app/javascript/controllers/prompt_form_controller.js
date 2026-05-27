import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count", "dictateButton"]

  connect() {
    this.loadDraftFromStorage()
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

  toggleDictation() {
    if (this.isDictating) {
      this.stopDictation()
    } else {
      this.startDictation()
    }
  }

  startDictation() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRecognition) {
      alert("Voice dictation is not supported in this browser.")
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.continuous = true
    this.recognition.interimResults = true
    this.recognition.lang = "en-US"

    this.isDictating = true
    this.dictationBase = this.inputTarget.value
    this.setDictationActive(true)

    this.recognition.onresult = (event) => {
      let finalTranscript = ""
      let interimTranscript = ""

      for (let i = 0; i < event.results.length; i++) {
        const result = event.results[i]
        const text = result[0].transcript
        if (result.isFinal) {
          finalTranscript += text
        } else {
          interimTranscript += text
        }
      }

      const base = this.dictationBase ?? ""
      const sessionTranscript = finalTranscript + interimTranscript
      const needsSeparator =
        base.trim().length > 0 && sessionTranscript.length > 0 && !/\s$/.test(base)
      const separator = needsSeparator ? " " : ""

      this.inputTarget.value = base + separator + sessionTranscript
      this.updateCount()
    }

    this.recognition.onerror = () => {
      this.stopDictation()
    }

    this.recognition.onend = () => {
      this.isDictating = false
      this.setDictationActive(false)
    }

    try {
      this.recognition.start()
    } catch {
      this.isDictating = false
    }
  }

  stopDictation() {
    this.isDictating = false
    this.dictationBase = null
    this.setDictationActive(false)
    try {
      this.recognition?.stop()
    } catch {
      // ignore
    }
  }

  setDictationActive(active) {
    if (!this.hasDictateButtonTarget) return

    this.dictateButtonTarget.dataset.active = active ? "true" : ""
    this.dictateButtonTarget.setAttribute("aria-pressed", active ? "true" : "false")
  }

  readSummary(event) {
    const text = event.params.text?.toString()?.trim()
    if (!text) return
    if (!window.speechSynthesis) return

    try {
      window.speechSynthesis.cancel()
      const utterance = new SpeechSynthesisUtterance(text)
      utterance.rate = 1.0
      utterance.pitch = 1.0
      window.speechSynthesis.speak(utterance)
    } catch {
      // ignore
    }
  }

  loadDraftFromStorage() {
    try {
      const draft = window.localStorage?.getItem("draftPromptText")
      if (!draft) return
      if (this.inputTarget.value.trim().length > 0) return

      this.inputTarget.value = draft
      window.localStorage?.removeItem("draftPromptText")
    } catch {
      // Ignore storage errors (private mode, blocked storage, etc.)
    }
  }
}
