// Turbo Drive swaps <body>; Google's v3 badge lives in the body and is removed each visit
// while api.js does not execute again. Detach before the swap and reattach after turbo:load.
let preservedRecaptchaBadge = null

document.addEventListener("turbo:before-render", function () {
  const badge = document.querySelector(".grecaptcha-badge")
  if (badge) {
    preservedRecaptchaBadge = badge
    badge.remove()
  }
})

document.addEventListener("turbo:load", function () {
  if (!preservedRecaptchaBadge || !document.body) return
  if (document.body.contains(preservedRecaptchaBadge)) return
  if (document.querySelector(".grecaptcha-badge")) {
    preservedRecaptchaBadge = null
    return
  }
  document.body.appendChild(preservedRecaptchaBadge)
})

// reCAPTCHA v3: run execute on contact form submit, fill g-recaptcha-response.
function interceptContactFormSubmit(event) {
  const form = event.target
  if (!form || form.tagName !== "FORM" || !form.classList.contains("contact-form")) return
  if (!window.__RECAPTCHA_SITE_KEY__) return

  if (form.dataset.recaptchaSubmitting === "true") {
    form.dataset.recaptchaSubmitting = ""
    return
  }

  event.preventDefault()

  if (typeof window.grecaptcha === "undefined" || typeof window.grecaptcha.execute !== "function") {
    return
  }

  window.grecaptcha.ready(function () {
    window.grecaptcha
      .execute(window.__RECAPTCHA_SITE_KEY__, { action: "contact" })
      .then(function (token) {
        const field = form.querySelector('input[name="g-recaptcha-response"]')
        if (field) field.value = token
        form.dataset.recaptchaSubmitting = "true"
        form.submit()
      })
      .catch(function (e) {
        console.warn("[recaptcha_turbo] execute failed", e)
      })
  })
}

document.addEventListener("submit", interceptContactFormSubmit, true)
