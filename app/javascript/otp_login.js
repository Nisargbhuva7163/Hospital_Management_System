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


    // 🔐 Email/Password Login Spinner
    const loginForm = document.querySelector("form[action='/users/sign_in']");
    const loginBtn = document.getElementById("loginBtn");
    const loginSpinner = document.getElementById("loginSpinner");
    const loginBtnText = document.getElementById("loginBtnText");

    if (loginForm) {
        loginForm.addEventListener("submit", () => {
            if (loginBtn && loginSpinner && loginBtnText) {
                loginBtn.disabled = true;
                loginSpinner.classList.remove("d-none");
                loginBtnText.textContent = "Logging in...";
            }
        });
    }

    const otpForm = document.getElementById("otpForm");
    const sendBtn = document.getElementById("sendOtpBtn");
    const otpSpinner = document.getElementById("otpSpinner");
    const otpBtnText = document.getElementById("otpButtonText");

    if (otpForm) {
        otpForm.addEventListener("submit", function (event) {
            event.preventDefault();
            const phone = otpForm.querySelector("input[name='phone_number']").value;
            sendBtn.disabled = true;
            otpSpinner.classList.remove("d-none");
            otpBtnText.textContent = "Sending...";

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
                    sendBtn.disabled = false;
                    otpSpinner.classList.add("d-none");
                    otpBtnText.textContent = "Send OTP";

                    if (data.success) {
                        document.getElementById("hiddenPhoneNumber").value = phone;
                        new bootstrap.Modal(document.getElementById("verifyOtpModal")).show();
                        showToast("OTP sent successfully!", "success");
                        startCountdown();
                    } else {
                        showToast(data.error || "Something went wrong!", "danger");
                    }
                })
                .catch(() => {
                    sendBtn.disabled = false;
                    otpSpinner.classList.add("d-none");
                    otpBtnText.textContent = "Send OTP";
                    showToast("Network error. Please try again.", "danger");
                });
        });

    }

    const verifyForm = document.getElementById("otpVerificationForm");
    const verifyBtn = document.getElementById("verifyOtpBtn");
    const verifySpinner = document.getElementById("verifySpinner");
    const verifyBtnText = document.getElementById("verifyBtnText");

    if (verifyForm) {
        verifyForm.addEventListener("submit", function (event) {
            event.preventDefault();
            const otpCode = verifyForm.querySelector("input[name='otp_code']").value;
            const phone = document.getElementById("hiddenPhoneNumber").value;

            verifyBtn.disabled = true;
            verifySpinner.classList.remove("d-none");
            verifyBtnText.textContent = "Verifying...";

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
                    verifyBtn.disabled = false;
                    verifySpinner.classList.add("d-none");
                    verifyBtnText.textContent = "Verify OTP";

                    if (data.success) {
                        showToast("OTP verified! Redirecting...", "success");
                        window.location.href = data.redirect_path;
                    } else {
                        showToast(data.error || "Invalid OTP", "danger");
                    }
                })
                .catch(() => {
                    verifyBtn.disabled = false;
                    verifySpinner.classList.add("d-none");
                    verifyBtnText.textContent = "Verify OTP";
                    showToast("Network error. Please try again.", "danger");
                });
        });
    }

    const resendBtn = document.getElementById("resendOtpBtn");
    const resendSpinner = document.getElementById("resendSpinner");
    const resendOtpText = document.getElementById("resendOtpText");

    if (resendBtn) {
        resendBtn.addEventListener("click", function () {
            const phone = document.getElementById("hiddenPhoneNumber").value;
            resendBtn.disabled = true;
            resendSpinner.classList.remove("d-none");
            resendOtpText.innerHTML = "Sending...";

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
                    resendSpinner.classList.add("d-none");
                    resendBtn.disabled = false;

                    if (data.success) {
                        showToast(data.message, "success");
                        startCountdown();
                    } else {
                        showToast(data.error, "danger");
                    }
                })
                .catch(() => {
                    resendSpinner.classList.add("d-none");
                    resendBtn.disabled = false;
                    resendOtpText.innerHTML = "Resend OTP";
                    showToast("Network error. Please try again.", "danger");
                });
        });
    }

    function startCountdown() {
        const countdownText = document.getElementById("resendCountdown");
        const resendOtpText = document.getElementById("resendOtpText");
        let timeLeft = 60;

        resendBtn.disabled = true;
        resendBtn.innerHTML = `Resend OTP in <span id="resendCountdown">${timeLeft}</span>s`;

        const interval = setInterval(() => {
            timeLeft--;

            const countdownSpan = document.getElementById("resendCountdown");
            if (countdownSpan) {
                countdownSpan.textContent = timeLeft;
            }

            if (timeLeft <= 0) {
                clearInterval(interval);
                resendBtn.disabled = false;
                resendBtn.innerHTML = `Resend OTP`;
            }
        }, 1000);
    }

});
