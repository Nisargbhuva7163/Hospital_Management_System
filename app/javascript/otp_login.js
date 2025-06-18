document.addEventListener("DOMContentLoaded", () => {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    function showToast(message, type = "danger") {
        const toastId = `toast-${Date.now()}`;
        const toastHTML = `
      <div id="${toastId}" class="toast align-items-center text-bg-${type} border-0 show mb-2" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="d-flex">
          <div class="toast-body">${message}</div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
      </div>
    `;
        const container = document.getElementById("toastContainer");
        container.insertAdjacentHTML("beforeend", toastHTML);
        setTimeout(() => {
            const toast = document.getElementById(toastId);
            if (toast) toast.remove();
        }, 5000);
    }

    const otpForm = document.getElementById("otpForm");
    if (otpForm) {
        otpForm.addEventListener("submit", function (event) {
            event.preventDefault();
            const phone = otpForm.querySelector("input[name='phone_number']").value;

            fetch("/users/send_otp", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": csrfToken
                },
                body: JSON.stringify({ phone_number: phone })
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById("hiddenPhoneNumber").value = phone;
                        new bootstrap.Modal(document.getElementById("verifyOtpModal")).show();
                        showToast("OTP sent successfully!", "success");
                        startCountdown();
                    } else {
                        showToast(data.error || "Something went wrong!", "danger");
                    }
                });
        });
    }

    const verifyForm = document.getElementById("otpVerificationForm");
    if (verifyForm) {
        verifyForm.addEventListener("submit", function (event) {
            event.preventDefault();
            const otpCode = verifyForm.querySelector("input[name='otp_code']").value;
            const phone = document.getElementById("hiddenPhoneNumber").value;

            fetch("/users/verify_otp", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": csrfToken
                },
                body: JSON.stringify({ phone_number: phone, otp_code: otpCode })
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        showToast("OTP verified! Redirecting...", "success");
                        window.location.href = data.redirect_path;
                    } else {
                        showToast(data.error || "Invalid OTP", "danger");
                    }
                });
        });
    }

    const resendBtn = document.getElementById("resendOtpBtn");
    if (resendBtn) {
        resendBtn.addEventListener("click", function () {
            const phone = document.getElementById("hiddenPhoneNumber").value;
            fetch("/users/resend_otp", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": csrfToken
                },
                body: JSON.stringify({ phone_number: phone })
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        showToast(data.message, "success");
                        startCountdown();
                    } else {
                        showToast(data.error, "danger");
                    }
                });
        });
    }

    function startCountdown() {
        const countdownText = document.getElementById("resendCountdown");
        let timeLeft = 15;

        resendBtn.disabled = true;
        countdownText.textContent = timeLeft;

        const interval = setInterval(() => {
            timeLeft--;
            countdownText.textContent = timeLeft;
            if (timeLeft <= 0) {
                clearInterval(interval);
                resendBtn.disabled = false;
                resendBtn.innerHTML = `Resend OTP`;
            }
        }, 1000);
    }
});
