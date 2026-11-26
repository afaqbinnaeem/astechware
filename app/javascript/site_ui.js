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
const HERO_HOLD_MS = 2200
const HERO_GAP_MS = 320

let heroWordTimer = null
let heroWordEl = null
let heroWordIndex = 0
let heroWordPaused = false
let heroWordRunning = false
let heroIndustryLeaveTimer = null

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

function showHeroIndustry(index) {
  const slides = document.querySelectorAll(".hero-industry-slide")
  if (!slides.length) return

  const nextIndex = ((index % slides.length) + slides.length) % slides.length
  const current = document.querySelector(".hero-industry-slide.is-active")
  const next = slides[nextIndex]
  if (!next || next === current) return

  if (heroIndustryLeaveTimer) {
    clearTimeout(heroIndustryLeaveTimer)
    heroIndustryLeaveTimer = null
  }

  slides.forEach(function (slide) {
    if (slide !== current) {
      slide.classList.remove("is-active", "is-leaving")
    }
  })

  if (current) {
    current.classList.remove("is-active")
    current.classList.add("is-leaving")
    heroIndustryLeaveTimer = setTimeout(function () {
      current.classList.remove("is-leaving")
      heroIndustryLeaveTimer = null
    }, 560)
  }

  next.classList.add("is-active")
}

function destroyHeroWordTypewriter() {
  clearHeroWordTimer()
  if (heroIndustryLeaveTimer) {
    clearTimeout(heroIndustryLeaveTimer)
    heroIndustryLeaveTimer = null
  }
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
  showHeroIndustry(0)
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
  showHeroIndustry(heroWordIndex)
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
  showHeroIndustry(0)

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


function lineToneClass(tone) {
  return tone === "white" ? " is-on-white" : ""
}

function relRect(section, el) {
  const sr = section.getBoundingClientRect()
  const r = el.getBoundingClientRect()
  return {
    left: r.left - sr.left,
    top: r.top - sr.top,
    right: r.right - sr.left,
    bottom: r.bottom - sr.top,
    width: r.width,
    height: r.height,
    cx: r.left - sr.left + r.width / 2,
    cy: r.top - sr.top + r.height / 2
  }
}

function underlineBox(section, heading) {
  const ref = heading.querySelector(".flow-lines-underline-ref, .branch-lines-underline-ref")
  if (ref) {
    const u = relRect(section, ref)
    return {
      left: u.left,
      right: u.right,
      y: u.top + u.height / 2,
      top: u.top,
      bottom: u.bottom
    }
  }
  const after = window.getComputedStyle(heading, "::after")
  const r = relRect(section, heading)
  const uw = parseFloat(after.width) || 80
  const uh = parseFloat(after.height) || 5
  const left = r.left + (r.width - uw) / 2
  return { left: left, right: left + uw, y: r.bottom - uh / 2, top: r.bottom - uh, bottom: r.bottom }
}

function appendSvgPath(svg, d, className) {
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("d", d)
  path.setAttribute("class", className)
  svg.appendChild(path)
  return path
}

function appendSvgCircle(svg, cx, cy, r, className) {
  const c = document.createElementNS("http://www.w3.org/2000/svg", "circle")
  c.setAttribute("cx", String(cx))
  c.setAttribute("cy", String(cy))
  c.setAttribute("r", String(r))
  c.setAttribute("class", className)
  svg.appendChild(c)
  return c
}

function setSvgSize(svg, w, h) {
  svg.setAttribute("viewBox", "0 0 " + w + " " + h)
  svg.setAttribute("width", String(w))
  svg.setAttribute("height", String(h))
}

/* ---------- Section tone alternating ---------- */
function initSectionTones() {
  const nodes = document.querySelectorAll(".section-tone-gradient")
  let index = 0
  nodes.forEach(function (el) {
    el.classList.toggle("section-tone-gradient-alt", index % 2 === 1)
    index += 1
  })
}

/* ---------- Flow lines (What we build) ---------- */
let flowLinesCleanup = null
function destroyFlowLines() {
  if (typeof flowLinesCleanup === "function") {
    flowLinesCleanup()
    flowLinesCleanup = null
  }
}

function initFlowLines() {
  destroyFlowLines()
  const section = document.querySelector(".flow-lines-section")
  if (!section) return
  const svg = section.querySelector(".flow-lines-svg")
  const heading = section.querySelector(".flow-lines-heading")
  const underlineRef = section.querySelector(".flow-lines-underline-ref")
  const subtitle = section.querySelector(".flow-lines-subtitle")
  const cards = section.querySelector(".flow-lines-cards")
  if (!svg || !heading) return

  const mq = window.matchMedia("(max-width: 767.98px)")
  const tone = svg.getAttribute("data-line-tone") || "gradient"
  const toneCls = lineToneClass(tone)
  let frame = 0

  function draw() {
    svg.innerHTML = ""
    if (mq.matches) return
    const w = section.clientWidth
    const h = section.clientHeight
    if (w < 8 || h < 8) return
    setSvgSize(svg, w, h)

    const hr = relRect(section, heading)
    const u = underlineBox(section, heading)
    const sub = subtitle ? relRect(section, subtitle) : null
    const cardsTop = cards ? relRect(section, cards).top : h
    const gap = 24
    // Tangled zone stays in empty area left of the heading
    const leftLimit = Math.max(48, hr.left - gap)
    const rightStart = Math.min(w - 24, hr.right + gap)
    const amp = 60
    // Never enter the subtitle band; keep swing above cards
    const maxY = Math.min(cardsTop - 16, sub ? sub.top - 12 : cardsTop - 16, u.y + amp)
    const minY = Math.max(8, Math.min(hr.top, u.y - amp))
    function clampY(y) {
      return Math.max(minY, Math.min(maxY, y))
    }

    const greyYs = [u.y - 10, u.y - 2, u.y + 6, u.y + 14].map(clampY)
    greyYs.forEach(function (y, i) {
      const a1 = clampY(y + (i % 2 ? -amp * 0.55 : amp * 0.5))
      const a2 = clampY(y + (i % 2 ? amp * 0.45 : -amp * 0.4))
      const leftD =
        "M0 " + clampY(y + 8) +
        " C" + (leftLimit * 0.2) + " " + a1 +
        " " + (leftLimit * 0.45) + " " + a2 +
        " " + (leftLimit * 0.7) + " " + clampY(y + (i % 2 ? -12 : 10)) +
        " C" + (leftLimit * 0.85) + " " + y +
        " " + (leftLimit - 8) + " " + y +
        " " + leftLimit + " " + y
      appendSvgPath(svg, leftD, "decor-line-path" + toneCls)
      // Resume after heading text gap
      appendSvgPath(svg, "M" + rightStart + " " + y + " L" + w + " " + y, "decor-line-path" + toneCls)
    })

    // Yellow: messy left (≤60px swing), then flat into measured underline left
    const yY = u.y
    const flatStart = Math.max(leftLimit, u.left - 40)
    const yellowD =
      "M0 " + clampY(yY + 18) +
      " C" + (leftLimit * 0.25) + " " + clampY(yY - amp * 0.7) +
      " " + (leftLimit * 0.5) + " " + clampY(yY + amp * 0.55) +
      " " + (leftLimit * 0.78) + " " + clampY(yY - 6) +
      " L" + flatStart + " " + yY +
      " L" + u.left + " " + yY
    appendSvgPath(svg, yellowD, "decor-line-path is-accent")

    ;[greyYs[0], greyYs[2], greyYs[3]].forEach(function (y, i) {
      const p = appendSvgPath(
        svg,
        "M" + rightStart + " " + y + " L" + w + " " + y,
        "flow-lines-pulse"
      )
      p.style.animationDelay = (-1.1 * i) + "s"
    })
  }

  function schedule() {
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(draw)
  }
  const ro = new ResizeObserver(schedule)
  ro.observe(section)
  ro.observe(heading)
  if (underlineRef) ro.observe(underlineRef)
  schedule()
  flowLinesCleanup = function () {
    cancelAnimationFrame(frame)
    ro.disconnect()
    svg.innerHTML = ""
  }
}

/* ---------- Branch lines (Industries) ---------- */
let branchLinesCleanup = null
function destroyBranchLines() {
  if (typeof branchLinesCleanup === "function") {
    branchLinesCleanup()
    branchLinesCleanup = null
  }
}

function initBranchLines() {
  destroyBranchLines()
  const section = document.querySelector(".branch-lines-section")
  if (!section) return
  const svg = section.querySelector(".branch-lines-svg")
  const heading = section.querySelector(".branch-lines-heading")
  const underlineRef = section.querySelector(".branch-lines-underline-ref")
  const grid = section.querySelector(".branch-lines-grid")
  if (!svg || !heading || !grid) return
  const mq = window.matchMedia("(max-width: 767.98px)")
  const tone = svg.getAttribute("data-line-tone") || "gradient"
  const toneCls = lineToneClass(tone)
  let frame = 0

  function clusterRows(cardRects) {
    const rows = []
    cardRects.forEach(function (cr, i) {
      let row = rows.find(function (candidate) { return Math.abs(candidate.top - cr.top) < 10 })
      if (!row) {
        row = { top: cr.top, bottom: cr.bottom, cards: [] }
        rows.push(row)
      }
      row.cards.push(Object.assign({ index: i }, cr))
      row.bottom = Math.max(row.bottom, cr.bottom)
      row.top = Math.min(row.top, cr.top)
    })
    rows.sort(function (a, b) { return a.top - b.top })
    return rows
  }

  function draw() {
    svg.innerHTML = ""
    if (mq.matches) return
    const w = section.clientWidth
    const h = section.clientHeight
    if (w < 8 || h < 8) return
    setSvgSize(svg, w, h)

    const u = underlineBox(section, heading)
    const hr = relRect(section, heading)
    const cards = Array.prototype.slice.call(grid.querySelectorAll(".branch-lines-card"))
    if (cards.length < 2) return
    const cardRects = cards.map(function (c) { return relRect(section, c) })
    const rows = clusterRows(cardRects)
    if (!rows.length) return
    if (Math.abs(rows[0].cards[0].cy - rows[0].cards[rows[0].cards.length - 1].cy) > 40 && rows[0].cards.length > 1) {
      // ok horizontal
    }
    if (rows.length >= 2 && Math.abs(rows[1].top - rows[0].top) < 20) return

    const gaps = []
    for (let i = 0; i < rows.length - 1; i++) gaps.push((rows[i].bottom + rows[i + 1].top) / 2)

    const topRow = rows[0]
    const cardsLeft = Math.min.apply(null, topRow.cards.map(function (c) { return c.left }))
    const cardsRight = Math.max.apply(null, topRow.cards.map(function (c) { return c.right }))
    const gutterInset = 12
    function clampG(x) { return Math.max(gutterInset, Math.min(w - gutterInset, x)) }
    const leftBase = Math.max(gutterInset + 16, cardsLeft - 32)
    const rightBase = Math.min(w - gutterInset - 16, cardsRight + 32)
    const leftXs = [leftBase - 8, leftBase, leftBase + 8].map(clampG)
    const rightXs = [rightBase - 8, rightBase, rightBase + 8].map(clampG)
    const fanEndY = Math.max(u.y + 24, rows[0].top - 10)
    const last = rows[rows.length - 1]
    const lastLeft = Math.min.apply(null, last.cards.map(function (c) { return c.left }))
    const lastRight = Math.max.apply(null, last.cards.map(function (c) { return c.right }))
    const emptyLeftX = (gutterInset + lastLeft) / 2
    const emptyRightX = (lastRight + w - gutterInset) / 2
    const emptyY = last.cards[0].cy
    const gridCx = (cardsLeft + cardsRight) / 2
    const headingGapLeft = hr.left - 24
    const headingGapRight = hr.right + 24

    function side(sideName) {
      const startX = sideName === "left" ? u.left : u.right
      const xs = sideName === "left" ? leftXs : rightXs
      const endEmptyX = sideName === "left" ? emptyLeftX : emptyRightX
      const inward = sideName === "left" ? 1 : -1
      xs.forEach(function (gx, li) {
        // Fan out below heading band so we don't cross heading text
        let d =
          "M" + startX + " " + u.y +
          " C" + (startX + (gx - startX) * 0.55) + " " + u.y +
          " " + gx + " " + u.y +
          " " + gx + " " + (u.y + Math.min(28, fanEndY - u.y)) +
          " L" + gx + " " + fanEndY
        const yellow = li >= gaps.length
        if (li < gaps.length) {
          const gy = gaps[li]
          const turn = 28
          const stopX = gridCx - inward * 24
          d += " L" + gx + " " + (gy - turn)
          d += " C" + gx + " " + (gy - turn * 0.25) + " " + (gx + inward * turn * 0.25) + " " + gy + " " + (gx + inward * turn) + " " + gy
          d += " L" + stopX + " " + gy
          const path = appendSvgPath(svg, d, "decor-line-path branch-lines-path" + toneCls + (yellow ? " is-accent" : ""))
          path.dataset.side = sideName
          path.dataset.role = "gap"
          path.dataset.gapIndex = String(li)
        } else {
          const approachY = emptyY - 40
          d += " L" + gx + " " + approachY
          d += " C" + gx + " " + (approachY + 22) + " " + (endEmptyX - inward * 22) + " " + emptyY + " " + endEmptyX + " " + emptyY
          const path = appendSvgPath(svg, d, "decor-line-path branch-lines-path is-accent")
          path.dataset.side = sideName
          path.dataset.role = "terminal"
          appendSvgCircle(svg, endEmptyX, emptyY, 4, "decor-line-dot is-accent")
        }
      })
    }
    side("left")
    side("right")
  }

  function clearActive() {
    svg.querySelectorAll(".is-active").forEach(function (el) { el.classList.remove("is-active") })
  }
  function onGridOver(event) {
    const card = event.target.closest(".branch-lines-card")
    if (!card || !grid.contains(card)) return
    const cards = Array.prototype.slice.call(grid.querySelectorAll(".branch-lines-card"))
    const index = cards.indexOf(card)
    if (index < 0) return
    const cardRects = cards.map(function (c) { return relRect(section, c) })
    const rows = clusterRows(cardRects)
    const gridR = relRect(section, grid)
    const cr = cardRects[index]
    const rowIndex = rows.findIndex(function (row) { return row.cards.some(function (c) { return c.index === index }) })
    const side = cr.cx < gridR.cx ? "left" : "right"
    clearActive()
    svg.querySelectorAll(".branch-lines-path").forEach(function (el) {
      if (el.dataset.side !== side) return
      if (el.dataset.role === "gap" && Number(el.dataset.gapIndex) === Math.max(0, rowIndex - 1)) el.classList.add("is-active")
      else if (el.dataset.role === "terminal" && rowIndex === rows.length - 1) el.classList.add("is-active")
      else if (el.dataset.role === "gap" && rowIndex === 0 && Number(el.dataset.gapIndex) === 0) el.classList.add("is-active")
    })
  }
  function onGridOut(event) {
    if (event.relatedTarget && grid.contains(event.relatedTarget)) return
    clearActive()
  }

  function schedule() {
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(draw)
  }
  const ro = new ResizeObserver(schedule)
  ro.observe(section)
  ro.observe(grid)
  if (underlineRef) ro.observe(underlineRef)
  grid.addEventListener("mouseover", onGridOver)
  grid.addEventListener("mouseout", onGridOut)
  schedule()
  branchLinesCleanup = function () {
    cancelAnimationFrame(frame)
    ro.disconnect()
    grid.removeEventListener("mouseover", onGridOver)
    grid.removeEventListener("mouseout", onGridOut)
    svg.innerHTML = ""
  }
}

/* ---------- Track lines (Featured work) ---------- */
let trackLinesCleanup = null
function destroyTrackLines() {
  if (typeof trackLinesCleanup === "function") {
    trackLinesCleanup()
    trackLinesCleanup = null
  }
}

function initTrackLines() {
  destroyTrackLines()
  const section = document.querySelector(".track-lines-section")
  if (!section) return
  const svg = section.querySelector(".track-lines-svg")
  const grid = section.querySelector(".track-lines-grid")
  const button = section.querySelector(".track-lines-button")
  if (!svg || !grid) return
  const mq = window.matchMedia("(max-width: 767.98px)")
  const tone = svg.getAttribute("data-line-tone") || "white"
  const toneCls = lineToneClass(tone)
  let frame = 0

  function applyPulse(path, delay) {
    const len = Math.max(path.getTotalLength(), 1)
    const dash = 28
    const period = dash + len
    path.style.strokeDasharray = dash + " " + len
    path.style.setProperty("--track-pulse-travel", String(-period))
    if (delay) path.style.animationDelay = delay
  }

  function draw() {
    svg.innerHTML = ""
    if (mq.matches) return
    const w = section.clientWidth
    const h = section.clientHeight
    if (w < 8 || h < 8) return
    setSvgSize(svg, w, h)
    const gridR = relRect(section, grid)
    const midY = gridR.top + gridR.height / 2
    const trackYs = [midY - 8, midY, midY + 8]
    const bottomY = trackYs[2]
    const tracks = trackYs.map(function (y) { return "M0 " + y + " L" + w + " " + y })
    tracks.forEach(function (d) { appendSvgPath(svg, d, "decor-line-path" + toneCls) })

    const pulses = [
      { d: tracks[0], delay: "0s" },
      { d: tracks[1], delay: "-1.3s" },
      { d: tracks[2], delay: "-2.6s" }
    ]

    if (button) {
      const btn = relRect(section, button)
      const leftBranchX = Math.max(18, Math.min(gridR.left * 0.55, gridR.left - 16))
      const rightBranchX = Math.min(w - 18, Math.max(gridR.right + 16, gridR.right + (w - gridR.right) * 0.45))
      const leftConnector =
        "M" + leftBranchX + " " + bottomY +
        " C" + leftBranchX + " " + (bottomY + (btn.cy - bottomY) * 0.55) +
        " " + leftBranchX + " " + btn.cy +
        " " + (leftBranchX + (btn.left - leftBranchX) * 0.35) + " " + btn.cy +
        " L" + btn.left + " " + btn.cy
      const rightConnector =
        "M" + rightBranchX + " " + bottomY +
        " C" + rightBranchX + " " + (bottomY + (btn.cy - bottomY) * 0.55) +
        " " + rightBranchX + " " + btn.cy +
        " " + (rightBranchX - (rightBranchX - btn.right) * 0.35) + " " + btn.cy +
        " L" + btn.right + " " + btn.cy
      appendSvgPath(svg, leftConnector, "decor-line-path" + toneCls)
      appendSvgPath(svg, rightConnector, "decor-line-path" + toneCls)
      pulses.push({ d: leftConnector, delay: "-0.7s" }, { d: rightConnector, delay: "-2.0s" })
    }

    pulses.forEach(function (spec) {
      const p = appendSvgPath(svg, spec.d, "track-lines-pulse")
      applyPulse(p, spec.delay)
    })
  }

  function schedule() {
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(draw)
  }
  const ro = new ResizeObserver(schedule)
  ro.observe(section)
  ro.observe(grid)
  if (button) ro.observe(button)
  schedule()
  trackLinesCleanup = function () {
    cancelAnimationFrame(frame)
    ro.disconnect()
    svg.innerHTML = ""
  }
}

/* ---------- Untangle line (Contact steps) ---------- */
let untangleLineCleanup = null
function destroyUntangleLine() {
  if (typeof untangleLineCleanup === "function") {
    untangleLineCleanup()
    untangleLineCleanup = null
  }
}

function initUntangleLine() {
  destroyUntangleLine()
  const section = document.querySelector(".untangle-line-section")
  if (!section) return
  const svg = section.querySelector(".untangle-line-svg")
  const circles = section.querySelectorAll(".untangle-line-circle")
  const texts = section.querySelectorAll(".untangle-line-text")
  if (!svg || circles.length < 3) return
  const mq = window.matchMedia("(max-width: 767.98px)")
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)")
  const tone = svg.getAttribute("data-line-tone") || "gradient"
  const toneCls = lineToneClass(tone)
  let frame = 0
  let drawnOnce = false
  let greyPath = null
  let yellowPath = null
  let io = null

  function prepHidden(path) {
    const len = Math.max(path.getTotalLength(), 1)
    path.style.strokeDasharray = String(len)
    path.style.strokeDashoffset = String(len)
    path.style.transition = "none"
  }
  function showFully(path) {
    path.style.transition = "none"
    path.style.strokeDasharray = "none"
    path.style.strokeDashoffset = "0"
  }
  function animateDraw(path, ms) {
    return new Promise(function (resolve) {
      prepHidden(path)
      path.getBoundingClientRect()
      path.style.transition = "stroke-dashoffset " + ms + "ms ease-out"
      requestAnimationFrame(function () { path.style.strokeDashoffset = "0" })
      setTimeout(resolve, ms + 30)
    })
  }

  function buildSplitGrey(c1, c2, c3, textRects) {
    // Tangled left -> c1, gentle to c2, straight to c3, but skip text boxes with 24px gaps
    const y = c1.cy
    const amp = 36
    let d = "M0 " + y
    const xA = c1.cx * 0.22
    const xB = c1.cx * 0.45
    const xC = c1.cx * 0.7
    d += " C" + (xA * 0.5) + " " + (y - amp) + " " + xA + " " + (y + amp) + " " + xA + " " + (y + 4)
    d += " C" + ((xA + xB) / 2) + " " + (y - amp * 0.9) + " " + xB + " " + (y + amp * 0.7) + " " + xB + " " + (y - 6)
    d += " C" + ((xB + xC) / 2) + " " + (y + amp * 0.55) + " " + xC + " " + (y - 10) + " " + xC + " " + y
    d += " C" + ((xC + c1.cx) / 2) + " " + y + " " + (c1.cx - 20) + " " + y + " " + c1.cx + " " + y

    function gapAround(fromX, toX, yLine, textR) {
      if (!textR) return " L" + toX + " " + yLine
      const leftStop = textR.left - 24
      const rightStart = textR.right + 24
      if (toX <= leftStop || fromX >= rightStart) return " L" + toX + " " + yLine
      let out = ""
      if (fromX < leftStop) out += " L" + leftStop + " " + yLine
      // lift above text then resume
      out += " M" + rightStart + " " + yLine
      if (toX > rightStart) out += " L" + toX + " " + yLine
      return out
    }

    // c1 -> c2 with soft wave, split around text[0]/text[1] if needed
    const mid12 = (c1.cx + c2.cx) / 2
    d += " C" + (c1.cx + (mid12 - c1.cx) * 0.4) + " " + (y - 10) + " " + mid12 + " " + (y + 10) + " " + c2.cx + " " + c2.cy
    // If path would cross text of step 1/2, we already stay near circle centers behind numbers; text has no opaque patch.
    // Split only when text rect intersects the horizontal band near y.
    ;[0, 1].forEach(function (i) {
      // no-op placeholder kept for clarity; path uses circle centers which sit left of text
    })
    d += " L" + c3.cx + " " + c3.cy
    return d
  }

  async function runDrawOnce() {
    if (drawnOnce) return
    if (!greyPath || !yellowPath) draw()
    if (!greyPath || !yellowPath) return
    drawnOnce = true
    if (reduceMotion.matches) {
      showFully(greyPath)
      showFully(yellowPath)
      return
    }
    await animateDraw(greyPath, 1400)
    await animateDraw(yellowPath, 500)
    showFully(greyPath)
    showFully(yellowPath)
  }

  function draw() {
    svg.innerHTML = ""
    greyPath = null
    yellowPath = null
    if (mq.matches) return
    const w = section.clientWidth
    const h = section.clientHeight
    if (w < 8 || h < 8) return
    const c1 = relRect(section, circles[0])
    const c2 = relRect(section, circles[1])
    const c3 = relRect(section, circles[2])
    // stacked layout -> skip
    if (Math.abs(c2.cy - c1.cy) > 28 || Math.abs(c3.cy - c1.cy) > 28) return
    if (c2.cx <= c1.cx || c3.cx <= c2.cx) return
    setSvgSize(svg, w, h)

    const textRects = Array.prototype.slice.call(texts).map(function (el) { return relRect(section, el) })
    // Build path that stops before each text block and resumes after
    const y = c1.cy
    const amp = 36
    let grey = "M0 " + y
    grey += " C" + (c1.cx * 0.2) + " " + (y - amp) + " " + (c1.cx * 0.4) + " " + (y + amp) + " " + (c1.cx * 0.55) + " " + (y - 8)
    grey += " C" + (c1.cx * 0.7) + " " + (y + 12) + " " + (c1.cx - 24) + " " + y + " " + c1.cx + " " + y

    function connectSkippingText(from, to, textR) {
      const mid = (from.cx + to.cx) / 2
      if (!textR || textR.bottom < from.cy - 20 || textR.top > from.cy + 20) {
        return " C" + (from.cx + (mid - from.cx) * 0.45) + " " + (from.cy - 10) + " " + mid + " " + (to.cy + 10) + " " + to.cx + " " + to.cy
      }
      const leftStop = Math.min(textR.left - 24, (from.cx + textR.left) / 2)
      const rightStart = Math.max(textR.right + 24, (textR.right + to.cx) / 2)
      let seg = " L" + leftStop + " " + from.cy
      seg += " M" + rightStart + " " + to.cy
      seg += " L" + to.cx + " " + to.cy
      return seg
    }

    grey += connectSkippingText(c1, c2, textRects[0])
    grey += connectSkippingText(c2, c3, textRects[1])

    greyPath = appendSvgPath(svg, grey, "decor-line-path" + toneCls)
    // Yellow after step 3: split around step 3 text if needed
    let yellow = "M" + c3.cx + " " + c3.cy
    if (textRects[2] && textRects[2].right + 24 < w) {
      const resume = textRects[2].right + 24
      yellow += " L" + Math.min(resume - 8, textRects[2].left - 24 > c3.cx ? textRects[2].left - 24 : c3.cx) + " " + c3.cy
      // from circle through to before text already at c3; resume after text to edge
      yellow = "M" + c3.cx + " " + c3.cy + " M" + resume + " " + c3.cy + " L" + w + " " + c3.cy
    } else {
      yellow += " L" + w + " " + c3.cy
    }
    yellowPath = appendSvgPath(svg, yellow, "decor-line-path is-accent")

    if (drawnOnce || reduceMotion.matches) {
      showFully(greyPath)
      showFully(yellowPath)
      if (reduceMotion.matches) drawnOnce = true
    } else {
      prepHidden(greyPath)
      prepHidden(yellowPath)
    }
  }

  function schedule() {
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(draw)
  }
  const ro = new ResizeObserver(schedule)
  ro.observe(section)
  circles.forEach(function (c) { ro.observe(c) })
  io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        runDrawOnce()
        if (io) { io.disconnect(); io = null }
      }
    })
  }, { threshold: 0.3 })
  io.observe(section)
  schedule()
  untangleLineCleanup = function () {
    cancelAnimationFrame(frame)
    ro.disconnect()
    if (io) { io.disconnect(); io = null }
    svg.innerHTML = ""
    drawnOnce = false
  }
}

/* ---------- Quote line (testimonials pagination) ---------- */
let quoteLineCleanup = null
function destroyQuoteLine() {
  if (typeof quoteLineCleanup === "function") {
    quoteLineCleanup()
    quoteLineCleanup = null
  }
}

function initQuoteLine() {
  destroyQuoteLine()
  const section = document.querySelector(".quote-line-section")
  if (!section) return
  const slider = section.querySelector(".clients-testimonials-slider")
  const lineLeft = section.querySelector(".quote-line--left")
  const lineRight = section.querySelector(".quote-line--right")
  if (!slider || !lineLeft || !lineRight) return
  if (typeof window.jQuery === "undefined") return
  const mq = window.matchMedia("(max-width: 767.98px)")
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)")
  let frame = 0

  function ensureIndicator(dots) {
    let indicator = dots.querySelector(".quote-line-indicator")
    if (!indicator) {
      indicator = document.createElement("span")
      indicator.className = "quote-line-indicator"
      indicator.setAttribute("aria-hidden", "true")
      dots.appendChild(indicator)
    }
    return indicator
  }

  function sync() {
    const dots = slider.querySelector(".slick-dots")
    if (!dots) {
      lineLeft.style.width = "0"
      lineRight.style.width = "0"
      return
    }
    const items = dots.querySelectorAll(":scope > li")
    const first = items[0]
    const last = items[items.length - 1]
    if (!first || !last) return
    const sr = section.getBoundingClientRect()
    const firstR = first.getBoundingClientRect()
    const lastR = last.getBoundingClientRect()
    const gap = 8
    const lineY = firstR.top - sr.top + firstR.height / 2 - 0.65
    lineLeft.style.top = lineY + "px"
    lineRight.style.top = lineY + "px"
    if (mq.matches) {
      lineLeft.style.width = "0"
      lineRight.style.width = "0"
    } else {
      const leftEnd = Math.max(0, firstR.left - sr.left - gap)
      const rightStart = Math.min(sr.width, lastR.right - sr.left + gap)
      lineLeft.style.left = "0"
      lineLeft.style.width = leftEnd + "px"
      lineRight.style.left = rightStart + "px"
      lineRight.style.width = Math.max(0, sr.width - rightStart) + "px"
    }
    const activeBtn = dots.querySelector("li.slick-active button")
    const indicator = ensureIndicator(dots)
    if (!activeBtn) return
    const btnRect = activeBtn.getBoundingClientRect()
    const dotsRect = dots.getBoundingClientRect()
    indicator.style.width = btnRect.width + "px"
    indicator.style.transition = reduceMotion.matches ? "none" : ""
    indicator.style.transform = "translateX(" + (btnRect.left - dotsRect.left) + "px)"
  }

  function schedule() {
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(sync)
  }
  const $slider = window.jQuery(slider)
  $slider.on("init.quoteLine reInit.quoteLine afterChange.quoteLine setPosition.quoteLine", schedule)
  const ro = new ResizeObserver(schedule)
  ro.observe(section)
  ro.observe(slider)
  schedule()
  setTimeout(schedule, 50)
  setTimeout(schedule, 300)
  quoteLineCleanup = function () {
    cancelAnimationFrame(frame)
    ro.disconnect()
    $slider.off(".quoteLine")
    const indicator = slider.querySelector(".quote-line-indicator")
    if (indicator) indicator.remove()
    lineLeft.style.width = "0"
    lineRight.style.width = "0"
  }
}

function onPageReady() {
  closeMobileNav()
  initEnterpriseNavHoverDropdowns()
  initClientsTestimonialsSlick()
  initMainSwiper()
  initHeroWordTypewriter()
  initSectionTones()
  initFlowLines()
  initBranchLines()
  initTrackLines()
  initUntangleLine()
  initQuoteLine()
}

function onBeforeCache() {
  closeMobileNav()
  destroyClientsTestimonialsSlick()
  destroyMainSwiper()
  destroyHeroWordTypewriter()
  destroyFlowLines()
  destroyBranchLines()
  destroyTrackLines()
  destroyUntangleLine()
  destroyQuoteLine()
}

document.addEventListener("DOMContentLoaded", onPageReady)
document.addEventListener("turbo:load", onPageReady)
document.addEventListener("turbo:before-cache", onBeforeCache)
