// Site chrome that must survive Turbo Drive visits.
// Loaded once via importmap — do not re-register these from inline body scripts.

function closeMobileNav() {
  document.body.classList.remove("open-dropdown")
  document.querySelectorAll(".nav-button.cmenu").forEach(function (el) {
    el.classList.remove("cmenu")
  })
}

// Delegated once — works after every Turbo body swap
document.addEventListener("click", function (event) {
  const btn = event.target.closest(".nav-button")
  if (!btn) return
  btn.classList.toggle("cmenu")
  document.body.classList.toggle("open-dropdown")
})

function initEnterpriseNavHoverDropdowns() {
  if (typeof window.bootstrap === "undefined") return

  document.querySelectorAll(".enterprise-nav .dropdown").forEach(function (dropdownEl) {
    if (dropdownEl.dataset.navHoverBound === "1") return
    dropdownEl.dataset.navHoverBound = "1"

    const toggle = dropdownEl.querySelector('[data-bs-toggle="dropdown"]')
    if (!toggle) return

    const bsDropdown = window.bootstrap.Dropdown.getOrCreateInstance(toggle)
    let leaveTimeout

    dropdownEl.addEventListener("mouseenter", function () {
      clearTimeout(leaveTimeout)
      bsDropdown.show()
    })
    dropdownEl.addEventListener("mouseleave", function () {
      leaveTimeout = setTimeout(function () {
        bsDropdown.hide()
      }, 120)
    })
  })
}

function destroyClientsTestimonialsSlick() {
  if (typeof window.jQuery === "undefined" || typeof window.jQuery.fn.slick === "undefined") return

  const $slider = window.jQuery(".clients-testimonials-slider")
  if ($slider.length && $slider.hasClass("slick-initialized")) {
    $slider.slick("unslick")
  }
}

function initClientsTestimonialsSlick() {
  if (typeof window.jQuery === "undefined" || typeof window.jQuery.fn.slick === "undefined") return

  const $slider = window.jQuery(".clients-testimonials-slider")
  if (!$slider.length) return

  if ($slider.hasClass("slick-initialized")) {
    $slider.slick("unslick")
  }

  $slider.slick({
    slidesToShow: 1,
    slidesToScroll: 1,
    arrows: false,
    dots: true,
    autoplay: true,
    autoplaySpeed: 5500,
    pauseOnHover: true,
    speed: 450,
    cssEase: "ease-in-out",
    adaptiveHeight: true
  })
}

function destroyMainSwiper() {
  const el = document.querySelector(".main-slider")
  if (el && el.swiper) {
    el.swiper.destroy(true, true)
  }
}

function initMainSwiper() {
  if (typeof window.Swiper === "undefined") return
  const el = document.querySelector(".main-slider")
  if (!el) return
  if (el.swiper) el.swiper.destroy(true, true)

  new window.Swiper(".main-slider", {
    loop: true,
    speed: 1000,
    autoplay: { delay: 3000 },
    loopAdditionalSlides: 10,
    grabCursor: true,
    navigation: {
      nextEl: ".swiper-button-next",
      prevEl: ".swiper-button-prev"
    },
    on: {
      init: function () {
        this.autoplay.stop()
      },
      slideChangeTransitionEnd: function () {
        const captions = this.el.querySelectorAll(".caption")
        for (let i = 0; i < captions.length; ++i) {
          captions[i].classList.remove("show")
        }
        const activeCaption = this.slides[this.activeIndex].querySelector(".caption")
        if (activeCaption) activeCaption.classList.add("show")
      },
      setTransition: function (speed) {
        for (let i = 0; i < this.slides.length; i++) {
          this.slides[i].style.transition = speed + "ms"
          const bg = this.slides[i].querySelector(".slide-bgimg")
          if (bg) bg.style.transition = speed + "ms"
        }
      }
    }
  })
}

const HERO_WORDS = [
  "legal",
  "healthcare",
  "construction",
  "logistics",
  "real estate",
  "field service"
]
const HERO_TYPE_MS = 70
const HERO_DELETE_MS = 45
const HERO_HOLD_MS = 1600
const HERO_GAP_MS = 320

let heroWordTimer = null
let heroWordEl = null
let heroWordIndex = 0
let heroWordPaused = false
let heroWordRunning = false

function prefersReducedMotion() {
  return (
    typeof window.matchMedia === "function" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  )
}

function clearHeroWordTimer() {
  if (heroWordTimer) {
    clearTimeout(heroWordTimer)
    heroWordTimer = null
  }
}

function destroyHeroWordTypewriter() {
  clearHeroWordTimer()
  heroWordRunning = false
  heroWordPaused = false
  if (heroWordEl) {
    heroWordEl.removeEventListener("mouseenter", pauseHeroWord)
    heroWordEl.removeEventListener("mouseleave", resumeHeroWord)
    heroWordEl.removeEventListener("focus", pauseHeroWord)
    heroWordEl.removeEventListener("blur", resumeHeroWord)
    heroWordEl.textContent = "legal"
    heroWordEl = null
  }
}

function pauseHeroWord() {
  heroWordPaused = true
}

function resumeHeroWord() {
  heroWordPaused = false
}

function scheduleHeroWord(delay, fn) {
  clearHeroWordTimer()
  heroWordTimer = setTimeout(function tick() {
    heroWordTimer = null
    if (!heroWordRunning || !heroWordEl) return
    if (heroWordPaused) {
      heroWordTimer = setTimeout(tick, 120)
      return
    }
    fn()
  }, delay)
}

function typeHeroWord(word, charIndex) {
  if (!heroWordEl) return
  heroWordEl.textContent = word.slice(0, charIndex)
  if (charIndex < word.length) {
    scheduleHeroWord(HERO_TYPE_MS, function () {
      typeHeroWord(word, charIndex + 1)
    })
    return
  }
  scheduleHeroWord(HERO_HOLD_MS, function () {
    deleteHeroWord(word)
  })
}

function deleteHeroWord(word) {
  if (!heroWordEl) return
  const current = heroWordEl.textContent || ""
  if (current.length > 0) {
    heroWordEl.textContent = current.slice(0, -1)
    scheduleHeroWord(HERO_DELETE_MS, function () {
      deleteHeroWord(word)
    })
    return
  }
  heroWordIndex = (heroWordIndex + 1) % HERO_WORDS.length
  scheduleHeroWord(HERO_GAP_MS, function () {
    typeHeroWord(HERO_WORDS[heroWordIndex], 0)
  })
}

function initHeroWordTypewriter() {
  destroyHeroWordTypewriter()

  const el = document.querySelector(".hero-section .hero-word")
  if (!el) return

  heroWordEl = el
  heroWordEl.textContent = "legal"
  heroWordIndex = 0

  if (prefersReducedMotion()) return

  heroWordEl.setAttribute("tabindex", "0")
  heroWordEl.addEventListener("mouseenter", pauseHeroWord)
  heroWordEl.addEventListener("mouseleave", resumeHeroWord)
  heroWordEl.addEventListener("focus", pauseHeroWord)
  heroWordEl.addEventListener("blur", resumeHeroWord)

  heroWordRunning = true
  // Hold the SSR "legal" before cycling so first paint is stable
  scheduleHeroWord(HERO_HOLD_MS, function () {
    deleteHeroWord("legal")
  })
}

function onPageReady() {
  closeMobileNav()
  initEnterpriseNavHoverDropdowns()
  initClientsTestimonialsSlick()
  initMainSwiper()
  initHeroWordTypewriter()
}

function onBeforeCache() {
  closeMobileNav()
  destroyClientsTestimonialsSlick()
  destroyMainSwiper()
  destroyHeroWordTypewriter()
}

document.addEventListener("DOMContentLoaded", onPageReady)
document.addEventListener("turbo:load", onPageReady)
document.addEventListener("turbo:before-cache", onBeforeCache)
