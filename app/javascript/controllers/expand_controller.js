import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "overlay", "expandBtn", "collapseBtn"]

  connect() {
    // If content doesn't actually overflow, hide the expand chrome entirely
    if (this.contentTarget.scrollHeight <= this.contentTarget.clientHeight + 2) {
      this.overlayTarget.classList.add("hidden")
      this.expandBtnTarget.classList.add("hidden")
      this.contentTarget.classList.remove("overflow-hidden")
    }
  }

  expand() {
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    this.contentTarget.classList.remove("overflow-hidden")
    this.overlayTarget.classList.add("hidden")
    this.expandBtnTarget.classList.add("hidden")
    this.collapseBtnTarget.classList.remove("hidden")
  }

  collapse() {
    this.contentTarget.style.maxHeight = "280px"
    this.contentTarget.classList.add("overflow-hidden")
    this.overlayTarget.classList.remove("hidden")
    this.expandBtnTarget.classList.remove("hidden")
    this.collapseBtnTarget.classList.add("hidden")
  }
}
