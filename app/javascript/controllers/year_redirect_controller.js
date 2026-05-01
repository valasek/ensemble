import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  change(event) {
    const year = event.target.value
    if (year) {
      window.location.href = this.urlValue + "/" + year
    }
  }
}
