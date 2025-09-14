<template>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <div class="brand gradient-text" ref="logo">MUMPS.IO</div>
      <div>
        <button class="btn" @click="toggleTheme" ref="btnTheme">
          {{ isDark ? 'Light theme' : 'Dark theme' }}
        </button>
      </div>
      <div style="display: flex; gap: 10px; justify-self: end">
        <button class="btn" @click="onSignUp" ref="btnSignup">Sign up</button>
        <button class="btn btn-primary" ref="btnStart" @click="$router.push('/practice')">
          Start practicing
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="content">
      <div class="hero">
        <div>
          <h1>
            <span class="gradient-text" ref="headline"
              >Master MUMPS with modern, hands-on practice.</span
            >
          </h1>
          <p class="sub" ref="tagline">
            A professional environment with a live terminal, curated problems, and practical guides
            — built for anyone maintaining or learning M across healthcare, finance, and enterprise
            systems.
          </p>
        </div>
        <XtermPanel />
      </div>

      <div>
        <div class="text-subtitle1" style="margin-bottom: 8px">Modules</div>
        <div class="modules">
          <div v-for="c in comps" :key="c.key" class="card" ref="cards">
            <div style="font-weight: 700">{{ c.title }}</div>
            <div class="text-caption" style="color: var(--text-dim); margin-top: 4px">
              {{ c.desc }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="footer-basic">
      <a href="#">Pricing</a>
      <a href="#">Docs</a>
      <a href="#">Privacy</a>
      <a href="#">Terms</a>
      <a href="#">Contact</a>
    </div>
  </div>

  <!-- Mobile sticky CTA -->
  <div class="sticky-cta">
    <button class="btn" @click="onSignUp">Sign up</button>
    <button class="btn btn-primary" ref="btnStart" @click="$router.push('/practice')">
      Start practicing
    </button>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import { Dark } from 'quasar'
import gsap from 'gsap'
import XtermPanel from '../components/XtermPanel.vue' // relative path (no '@' alias)

export default defineComponent({
  name: 'LandingPage',
  components: { XtermPanel },
  data() {
    return {
      isDark: Dark.isActive,
      comps: [
        {
          key: 'practice',
          title: 'Practice',
          desc: 'Interview-style problems with instant verdicts',
        },
        { key: 'learn', title: 'Learn', desc: 'Concise lessons on syntax, globals, and I/O' },
        {
          key: 'playground',
          title: 'Playground',
          desc: 'Interactive REPL and snippets with a mock DB',
        },
        { key: 'docs', title: 'Docs', desc: 'Quick reference for M, GT.M, and InterSystems' },
      ],
    }
  },
  mounted() {
    // ensure theme from storage
    const saved = localStorage.getItem('theme')
    if (saved === 'dark') {
      Dark.set(true)
      this.isDark = true
    } else if (saved === 'light') {
      Dark.set(false)
      this.isDark = false
    }

    // GSAP entrances (refs exist and are not conditionally rendered)
    gsap.from(this.$refs.logo, { y: -10, opacity: 0, duration: 0.45, ease: 'power2.out' })
    gsap.from(this.$refs.headline, { y: 16, opacity: 0, duration: 0.6, ease: 'power3.out' })
    gsap.from(this.$refs.tagline, {
      y: 10,
      opacity: 0,
      delay: 0.08,
      duration: 0.5,
      ease: 'power2.out',
    })
    gsap.from([this.$refs.btnTheme, this.$refs.btnSignup, this.$refs.btnStart], {
      y: 8,
      opacity: 0,
      duration: 0.45,
      ease: 'power2.out',
      stagger: 0.06,
      delay: 0.1,
    })
    // const cards = this.$el.querySelectorAll('.modules .card')
    const cards = this.$refs.cards
    gsap.from(cards, {
      y: 8,
      opacity: 0,
      duration: 0.45,
      ease: 'power2.out',
      stagger: 0.04,
      delay: 0.12,
    })
  },
  methods: {
    toggleTheme() {
      this.isDark = !this.isDark
      Dark.set(this.isDark)
      localStorage.setItem('theme', this.isDark ? 'dark' : 'light')
      window.dispatchEvent(new CustomEvent('theme-change')) // tells xterm to refresh theme
    },
    onSignUp() {},
    onStart() {},
  },
})
</script>
