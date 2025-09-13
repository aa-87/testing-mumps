<template>
  <div class="term-stack surface">
    <div class="term-bg" aria-hidden="true"></div>
    <div class="term-fore">
      <div ref="host" class="term-wrap"></div>
    </div>
  </div>
</template>
<script>
import { defineComponent, nextTick } from 'vue'
import { Terminal } from 'xterm'
import { FitAddon } from 'xterm-addon-fit'
import 'xterm/css/xterm.css'

function getTermTheme() {
  const s = getComputedStyle(document.body)
  return {
    background: s.getPropertyValue('--term-bg').trim() || '#101318',
    foreground: s.getPropertyValue('--term-fg').trim() || '#F6F9FF',
    black: s.getPropertyValue('--term-bg').trim() || '#101318',
    white: s.getPropertyValue('--term-fg').trim() || '#F6F9FF',
    brightBlack: '#4B5563',
    brightWhite: '#E5E7EB',
    cursor: s.getPropertyValue('--term-fg').trim() || '#F6F9FF',
  }
}

export default defineComponent({
  name: 'XtermPanel',
  data() {
    return {
      term: null,
      fit: null,
      ro: null,
      onTheme: null,
      onResize: null,
      state: { X: '', A1: '' },
    }
  },
  async mounted() {
    const term = new Terminal({
      convertEol: true,
      cursorBlink: true,
      rendererType: 'canvas',
      fontSize: 14,
      lineHeight: 1.25,
      fontFamily:
        'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
      theme: getTermTheme(),
    })
    const fit = new FitAddon()
    term.loadAddon(fit)
    term.open(this.$refs.host)
    this.term = term
    this.fit = fit

    const applySizing = () => {
      if (window.innerWidth >= 1024) {
        term.options.fontSize = 14
        term.options.lineHeight = 1.25
        try {
          term.resize(80, 24)
        } catch (e) {
          console.log(e)
        }
      } else {
        term.options.fontSize = 13
        term.options.lineHeight = 1.2
        try {
          fit.fit()
        } catch (e) {
          console.log(e)
        }
      }
    }

    // Fit after initial paint/layout
    await nextTick()
    setTimeout(() => {
      try {
        fit.fit()
        applySizing()
      } catch (e) {
        console.log(e)
      }
    }, 0)

    // ResizeObserver on the host so background/terminal always syncs
    this.ro = new ResizeObserver(() => {
      try {
        fit.fit()
      } catch (e) {
        console.log(e)
      }
    })
    this.ro.observe(this.$refs.host)

    // Window resize + theme change
    this.onResize = () => {
      try {
        fit.fit()
        applySizing()
      } catch (e) {
        console.log(e)
      }
    }
    window.addEventListener('resize', this.onResize, { passive: true })

    this.onTheme = () => {
      term.options.theme = getTermTheme()
      try {
        fit.fit()
        applySizing()
      } catch (e) {
        console.log(e)
      }
    }
    window.addEventListener('theme-change', this.onTheme)

    // Input handling
    let buffer = ''
    const prompt = () => term.write('\r\nUSER> ')
    const writeln = (s) => term.writeln(s)
    const write = (s) => term.write(s)
    term.onData((data) => {
      const code = data.charCodeAt(0)
      if (code === 13) {
        this.execute(buffer.trim(), writeln, write, prompt)
        buffer = ''
      } else if (code === 127) {
        if (buffer.length > 0) {
          buffer = buffer.slice(0, -1)
          write('\b \b')
        }
      } else {
        buffer += data
        write(data)
      }
    })

    // Demo typing
    this.demo(term, prompt)
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.onResize || (() => {}))
    window.removeEventListener('theme-change', this.onTheme || (() => {}))
    try {
      this.ro && this.ro.disconnect()
    } catch (e) {
      console.log(e)
    }
    try {
      this.term && this.term.dispose()
    } catch (e) {
      console.log(e)
    }
  },
  methods: {
    async demo(term, prompt) {
      const type = async (s, d = 24) => {
        for (const ch of s) {
          term.write(ch)
          await new Promise((r) => setTimeout(r, d))
        }
      }
      const enter = async () => {
        term.write('\r')
        await new Promise((r) => setTimeout(r, 140))
      }
      term.writeln('MUMPS 1.0 (mock)  \\xA9 MUMPS.IO')
      prompt()
      await type('SET X=42')
      await enter()
      prompt()
      await type('WRITE X')
      await enter()
      term.writeln('42')
      prompt()
      await type('SET ^A(1)=100')
      await enter()
      prompt()
      await type('ZWRITE ^A')
      await enter()
      term.writeln('^A(1)=100')
      prompt()
    },
    execute(line, writeln, write, prompt) {
      if (!line) return prompt()
      const up = line.toUpperCase()
      if (up.startsWith('SET X=')) {
        this.state.X = line.split('=')[1] || ''
        writeln('')
        prompt()
      } else if (up === 'WRITE X') {
        writeln(this.state.X || '')
        prompt()
      } else if (up.startsWith('SET ^A(1)=')) {
        this.state.A1 = line.split('=')[1] || ''
        writeln('')
        prompt()
      } else if (up.startsWith('ZWRITE ^A')) {
        writeln(`^A(1)=${this.state.A1 || '100'}`)
        prompt()
      } else if (up === 'HALT' || up === 'H') {
        writeln('Halting... (mock)')
      } else {
        write('?\n\r')
        prompt()
      }
    },
  },
})
</script>
