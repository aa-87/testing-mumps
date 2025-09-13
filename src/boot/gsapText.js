import { boot } from 'quasar/wrappers'
export default boot(async () => {
  const gsap = (await import('gsap')).default
  const q = (sel) => Array.from(document.querySelectorAll(sel))
  requestAnimationFrame(() => {
    q('[data-hero-letters]').forEach((el) => {
      const text = el.textContent ?? ''
      el.innerHTML = text
        .split('')
        .map((c) => `<span class="inline-block">${c === ' ' ? '&nbsp;' : c}</span>`)
        .join('')
      const spans = el.querySelectorAll('span')
      gsap.set(spans, { y: 24, opacity: 0, rotate: 2 })
      gsap.to(spans, {
        y: 0,
        opacity: 1,
        rotate: 0,
        duration: 0.7,
        ease: 'power3.out',
        stagger: 0.018,
      })
    })
  })
})
