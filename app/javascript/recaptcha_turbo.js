function renderContactRecaptchaWidgets() {
  if (typeof window.grecaptcha === "undefined" || typeof window.grecaptcha.render !== "function") {
    return
  }

  window.grecaptcha.ready(function () {
    document.querySelectorAll(".g-recaptcha").forEach(function (el) {
      if (el.querySelector("iframe")) return
      const sitekey = el.getAttribute("data-sitekey")
      if (!sitekey) return
      try {
        window.grecaptcha.render(el, { sitekey: sitekey })
      } catch (e) {
        console.warn("[recaptcha_turbo] render failed", e)
      }
    })
  })
}

document.addEventListener("turbo:load", renderContactRecaptchaWidgets)
