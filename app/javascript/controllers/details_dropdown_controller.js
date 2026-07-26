import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundCloseOnOutsideClick, true)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick, true)
  }

  closeOnOutsideClick(event) {
    if (!this.element.open) return
    if (this.element.contains(event.target)) return

    this.element.open = false
  }
}
