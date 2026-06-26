import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "ensemble-theme"
const THEMES = ["light", "dark", "auto"]

export default class extends Controller {
  static targets = ["select"]

  connect() {
    const savedTheme = this.readSavedTheme()
    this.applyTheme(savedTheme)
    this.syncTargets(savedTheme)
  }

  change(event) {
    const selectedTheme = this.normalizeTheme(event.target.value)
    this.saveTheme(selectedTheme)
    this.applyTheme(selectedTheme)
    this.syncTargets(selectedTheme)
  }

  readSavedTheme() {
    const saved = localStorage.getItem(STORAGE_KEY)
    return this.normalizeTheme(saved)
  }

  saveTheme(theme) {
    localStorage.setItem(STORAGE_KEY, theme)
  }

  normalizeTheme(theme) {
    return THEMES.includes(theme) ? theme : "auto"
  }

  applyTheme(theme) {
    const root = document.documentElement

    if (theme === "auto") {
      root.removeAttribute("data-theme")
      return
    }

    root.setAttribute("data-theme", theme)
  }

  syncTargets(theme) {
    this.selectTargets.forEach((target) => {
      target.value = theme
    })
  }
}
