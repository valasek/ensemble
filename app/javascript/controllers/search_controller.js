// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "stats"]
  static values = {
    url: { type: String, default: "/search/proxy" }
  }

  connect() {
    this.timeout = null
    this.abortController = null
  }

  search(event) {
    clearTimeout(this.timeout)
    
    const query = this.inputTarget.value.trim()
    
    if (query.length < 2) {
      this.clearResults()
      return
    }

    this.showLoading()
    
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          q: query,
          limit: 10
        }),
        signal: this.abortController.signal
      })

      if (!response.ok) {
        throw new Error('Search failed')
      }

      const data = await response.json()
      console.log("Search results:", data)
      this.displayResults(data, query)
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
        this.showError()
      }
    }
  }

  displayResults(data, query) {
    const hits = data.hits || []
    const total = data.estimatedTotalHits || 0
    const timeMs = data.processingTimeMs || 0

    if (this.hasStatsTarget) {
      this.statsTarget.textContent = `${total} výsledkov (${timeMs} ms)`
    }

    if (hits.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="no-results">
          <p>Žiadne výsledky pre <strong>${this.escapeHtml(query)}</strong></p>
        </div>
      `
      this.resultsTarget.classList.add('visible')
      return
    }

    this.resultsTarget.innerHTML = hits.map(hit => {
      const name = hit.name || hit.title || ''
      const excerpt = hit.excerpt || hit.description || ''
      const assemblyName = hit.assembly_name || ''
      const url = hit.url || '#'
      
      // Určenie typu a ikony
      const type = hit._type || 'performance'
      const typeLabel = type === 'member' ? 'Člen' : 'Účinkovanie'
      const typeIcon = type === 'member' ? '👤' : '🎭'
      
      return `
        <a href="${url}" class="search-result">
          <div class="search-result-header">
            <h3 class="search-result-title">${this.highlight(name, query)}</h3>
            <span class="search-result-type" title="${typeLabel}">${typeIcon}</span>
          </div>
          ${excerpt ? `<p class="search-result-excerpt">${this.highlight(excerpt, query)}</p>` : ''}
          <!--${assemblyName ? `<span class="search-result-category">${this.escapeHtml(assemblyName)}</span>` : ''}-->
        </a>
      `
    }).join('')

    this.resultsTarget.classList.add('visible')
  }

  highlight(text, query) {
    // Safety check: ensure text is a string
    if (!text) return ''
    if (!query) return String(text)
    
    // Convert to string if it's not already
    const textStr = String(text)
    const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi')
    return textStr.replace(regex, '<mark>$1</mark>')
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  escapeRegex(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  }

  clearResults() {
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.classList.remove('visible')
    if (this.hasStatsTarget) {
      this.statsTarget.textContent = ''
    }
  }

  showLoading() {
    if (this.hasStatsTarget) {
      this.statsTarget.textContent = 'Vyhľadávam ...'
    }
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="error">
        <p>Vyhľadávanie je dočasne nedostupné. Prosím, skúste to znova.</p>
      </div>
    `
    this.resultsTarget.classList.add('visible')
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.clearResults()
    }
  }

  handleKeydown(event) {
    const results = this.resultsTarget.querySelectorAll('.search-result')
    
    if (results.length === 0) return

    const currentIndex = Array.from(results).findIndex(r => 
      r.classList.contains('active')
    )

    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.setActive(results, currentIndex + 1)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.setActive(results, currentIndex - 1)
    } else if (event.key === 'Enter' && currentIndex >= 0) {
      event.preventDefault()
      results[currentIndex].click()
    } else if (event.key === 'Escape') {
      this.clearResults()
      this.inputTarget.blur()
    }
  }

  setActive(results, index) {
    results.forEach(r => r.classList.remove('active'))
    
    if (index >= 0 && index < results.length) {
      results[index].classList.add('active')
      results[index].scrollIntoView({ block: 'nearest' })
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}
