import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="booking-modal"
export default class extends Controller {
    static targets = ["bookingData", "bookingMessage", "bookingTimesList"]

    connect() {
        console.log("connected")
        // Parse booking windows JSON data from data attribute
        const bookingWindows = JSON.parse(this.bookingDataTarget.dataset.bookingWindows)

        // Set the message text
        this.bookingMessageTarget.textContent =
            "🚫 Booking is currently closed. Please try again during these time slots:"

        // Clear any existing list items
        this.bookingTimesListTarget.innerHTML = ""

        // Insert each booking window as a list item
        bookingWindows.forEach(window => {
            const li = document.createElement("li")
            li.textContent = `${window.start} to ${window.end}`
            this.bookingTimesListTarget.appendChild(li)
        })

        // Initialize and show the Bootstrap modal
        const modal = new bootstrap.Modal(this.element,{
            backdrop: 'static',
            keyboard: false
        })
        modal.show()
    }
}
