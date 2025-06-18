import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu", "toggle"]

    connect() {
        this.handleOutsideClick = this.closeOnOutsideClick.bind(this)
        document.addEventListener("click", this.handleOutsideClick)
        document.addEventListener("keydown", this.closeOnEscape.bind(this))
    }

    disconnect() {
        document.removeEventListener("click", this.handleOutsideClick)
    }

    toggleMenu(event) {
        event.preventDefault()
        const expanded = this.toggleTarget.getAttribute("aria-expanded") === "true"
        this.menuTarget.style.display = expanded ? "none" : "block"
        this.toggleTarget.setAttribute("aria-expanded", !expanded)
        this.menuTarget.setAttribute("aria-hidden", expanded)
    }

    closeOnEscape(event) {
        if (event.key === "Escape") {
            this.menuTarget.style.display = "none"
            this.toggleTarget.setAttribute("aria-expanded", "false")
            this.menuTarget.setAttribute("aria-hidden", "true")
            this.toggleTarget.focus()
        }
    }

    closeOnOutsideClick(event) {
        if (!this.element.contains(event.target)) {
            this.menuTarget.style.display = "none"
            this.toggleTarget.setAttribute("aria-expanded", "false")
            this.menuTarget.setAttribute("aria-hidden", "true")
        }
    }
}
