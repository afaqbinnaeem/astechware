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
    slidesToShow: 3,
    slidesToScroll: 1,
    arrows: true,
    dots: true,
    autoplay: true,
    autoplaySpeed: 4000,
    pauseOnHover: true,
    speed: 500,
    cssEase: "ease-in-out",
    prevArrow:
      '<button type="button" class="slick-prev clients-slider-arrow" aria-label="Previous testimonial"><i class="fa fa-chevron-left"></i></button>',
    nextArrow:
      '<button type="button" class="slick-next clients-slider-arrow" aria-label="Next testimonial"><i class="fa fa-chevron-right"></i></button>',
    responsive: [
      { breakpoint: 1200, settings: { slidesToShow: 2 } },
      { breakpoint: 768, settings: { slidesToShow: 1, arrows: true } }
    ]
  })

  setTimeout(function () {
    window
      .jQuery(".clients-testimonials-slider .slick-prev, .clients-testimonials-slider .slick-next")
      .off("touchstart.clientsSlider")
      .on("touchstart.clientsSlider", function (e) {
        e.preventDefault()
        e.stopPropagation()
        const $button = window.jQuery(this)
        const $active = window.jQuery(".clients-testimonials-slider")
        if ($button.hasClass("slick-prev")) {
          $active.slick("slickPrev")
        } else if ($button.hasClass("slick-next")) {
          $active.slick("slickNext")
        }
        return false
      })
  }, 100)
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

function onPageReady() {
  closeMobileNav()
  initEnterpriseNavHoverDropdowns()
  initClientsTestimonialsSlick()
  initMainSwiper()
}

function onBeforeCache() {
  closeMobileNav()
  destroyClientsTestimonialsSlick()
  destroyMainSwiper()
}

document.addEventListener("DOMContentLoaded", onPageReady)
document.addEventListener("turbo:load", onPageReady)
document.addEventListener("turbo:before-cache", onBeforeCache)
