document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("appointments-form");
    const otpModalEl = document.getElementById("otpModal");
    const confirmModalEl = document.getElementById("confirmModal");

    const otpInput = document.getElementById("otp-code");
    const otpError = document.getElementById("otp-error");
    const verifyOtpBtn = document.getElementById("verify-otp-btn");
    const resendOtpLink = document.getElementById("resend-otp-link");

    const otpModal = otpModalEl ? new bootstrap.Modal(otpModalEl) : null;
    const confirmModal = confirmModalEl ? new bootstrap.Modal(confirmModalEl) : null;

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    let appointmentData = {};

    function fillForm(data) {
        document.getElementById("appointment_name").value = data.name || "";
        document.getElementById("appointment_email").value = data.email || "";
        document.getElementById("appointment_age").value = data.age || "";
        document.getElementById("appointment_gender").value = data.gender || "";
        document.getElementById("appointment_phone").value = data.phone_number || "";
    }

    if (form) {
        form.addEventListener("submit", function (e) {
            e.preventDefault();
            const errorBox = document.getElementById("form-errors");
            errorBox.classList.add("d-none");
            errorBox.innerHTML = "";

            appointmentData = {
                name: document.getElementById("appointment_name").value,
                age: document.getElementById("appointment_age").value,
                gender: document.getElementById("appointment_gender").value,
                phone_number: document.getElementById("appointment_phone").value,
                email: document.getElementById("appointment_email").value,
            };

            fetch(form.action, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": csrfToken,
                    "X-Requested-With": "XMLHttpRequest",
                },
                body: JSON.stringify({ appointment: appointmentData }),
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById("confirmModalContent").innerHTML = data.html;
                        confirmModal?.show();
                    } else {
                        errorBox.innerHTML = data.errors.map(e => `<div>• ${e}</div>`).join("");
                        errorBox.classList.remove("d-none");
                    }
                })
                .catch(() => {
                    errorBox.innerHTML = `<div>• Something went wrong during form submission.</div>`;
                    errorBox.classList.remove("d-none");
                });
        });
    }

    confirmModalEl?.addEventListener("click", function (e) {
        if (e.target.matches("#confirm-book-btn")) {
            e.preventDefault();
            confirmModal?.hide();

            if (otpModal) {
                fetch(`/organizations/${form.dataset.orgId}/appointments/send_otp`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "X-CSRF-Token": csrfToken,
                        "X-Requested-With": "XMLHttpRequest",
                    },
                    body: JSON.stringify({ appointment: appointmentData }),
                })
                    .then(res => res.json())
                    .then(data => {
                        if (data.success) {
                            otpInput.value = "";
                            otpError.textContent = "";
                            otpModal?.show();
                            startResendOtpTimer();
                        } else {
                            document.getElementById("form-errors").innerHTML = `<div>• ${data.error || "Failed to send OTP."}</div>`;
                            document.getElementById("form-errors").classList.remove("d-none");
                        }
                    });
            } else {
                fetch(form.action, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "X-CSRF-Token": csrfToken,
                        "X-Requested-With": "XMLHttpRequest",
                    },
                    body: JSON.stringify({ appointment: appointmentData, confirm: "true" }),
                })
                    .then(res => res.json())
                    .then(data => {
                        if (data.success && data.redirect_path) {
                            window.location.href = data.redirect_path;
                        } else {
                            document.getElementById("form-errors").innerHTML = data.errors.map(e => `<div>• ${e}</div>`).join("");
                            document.getElementById("form-errors").classList.remove("d-none");
                        }
                    });
            }
        } else if (e.target.matches("#edit-appointment-btn")) {
            e.preventDefault();
            confirmModal?.hide();
            fillForm(appointmentData);
            document.getElementById("appointment-section").scrollIntoView({ behavior: "smooth" });
        }
    });

    verifyOtpBtn?.addEventListener("click", function () {
        const otpCode = otpInput.value.trim();
        if (!otpCode) {
            otpError.textContent = "Please enter the OTP.";
            return;
        }

        fetch(`/organizations/${form.dataset.orgId}/appointments/verify_otp`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken,
                "X-Requested-With": "XMLHttpRequest",
            },
            body: JSON.stringify({
                phone_number: appointmentData.phone_number,
                otp_code: otpCode,
                appointment: appointmentData,
            }),
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    otpModal?.hide();
                    window.location.href = data.redirect_path;
                } else {
                    otpError.textContent = data.error || "Incorrect OTP.";
                }
            });
    });

    resendOtpLink?.addEventListener("click", function (e) {
        e.preventDefault();

        if (resendOtpLink.classList.contains("disabled")) return;

        otpError.textContent = "";
        resendOtpLink.classList.add("disabled");
        resendOtpLink.textContent = "Sending...";

        fetch(`/organizations/${form.dataset.orgId}/appointments/send_otp`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken,
                "X-Requested-With": "XMLHttpRequest",
            },
            body: JSON.stringify({ appointment: appointmentData }),
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    otpError.textContent = "✅ OTP has been resent.";
                    otpError.classList.remove("text-danger");
                    otpError.classList.add("text-success");
                    startResendOtpTimer();
                } else {
                    resendOtpLink.classList.remove("disabled");
                    resendOtpLink.textContent = "Resend OTP";
                    otpError.textContent = data.error || "❌ Failed to resend OTP.";
                    otpError.classList.remove("text-success");
                    otpError.classList.add("text-danger");
                }
            })
            .catch(() => {
                resendOtpLink.classList.remove("disabled");
                resendOtpLink.textContent = "Resend OTP";
                otpError.textContent = "❌ Network error. Please try again.";
                otpError.classList.remove("text-success");
                otpError.classList.add("text-danger");
            });
    });

    function startResendOtpTimer() {
        let countdown = 60;
        resendOtpLink.classList.add("disabled");
        resendOtpLink.textContent = `Resend OTP in ${countdown}s`;

        const intervalId = setInterval(() => {
            countdown--;
            resendOtpLink.textContent = `Resend OTP in ${countdown}s`;

            if (countdown <= 0) {
                clearInterval(intervalId);
                resendOtpLink.classList.remove("disabled");
                resendOtpLink.textContent = "Resend OTP";
            }
        }, 1000);
    }
});
