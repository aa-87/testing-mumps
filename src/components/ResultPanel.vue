<template>
  <div class="rp">
    <div class="rp-head">
      <span class="title">Results</span>
      <span class="chip" :data-type="verdictType">{{ verdictText }}</span>
    </div>
    <div class="rp-body" ref="wrap">
      <div v-for="(r, i) in rows" :key="i" class="row" :data-type="r.type">
        <span class="tag">{{ tagLabel(r.type) }}</span>
        <div class="text">
          <pre><code>{{ r.text }}</code></pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import gsap from 'gsap'
export default {
  name: 'ResultPanel',
  props: {
    rows: { type: Array, default: () => [] },
    verdict: { type: String, default: '' },
  },
  computed: {
    verdictType() {
      const v = (this.verdict || '').toLowerCase()
      if (v.includes('accept')) return 'ok'
      if (v.includes('error') || v.includes('wrong')) return 'bad'
      if (v.includes('time') || v.includes('memory')) return 'bad'
      if (v) return 'warn'
      return ''
    },
    verdictText() {
      return this.verdict || '—'
    },
  },
  mounted() {
    this.$watch(
      () => this.rows.length,
      () => {
        const el = this.$refs.wrap
        if (!el) return
        const last = el.lastElementChild
        if (!last) return
        gsap.from(last, { y: 6, opacity: 0, duration: 0.25, ease: 'power2.out' })
        el.scrollTop = el.scrollHeight
      },
      { immediate: false },
    )
  },
  methods: {
    tagLabel(t) {
      return t === 'status'
        ? 'STATUS'
        : t === 'case'
          ? 'CASE'
          : t === 'verdict'
            ? 'VERDICT'
            : t === 'error'
              ? 'ERROR'
              : 'LOG'
    },
  },
}
</script>

<style scoped>
.rp {
  display: grid;
  grid-template-rows: auto 1fr;
  height: 100%;
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: hidden;
}
.rp-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 8px 10px;
  background: color-mix(in srgb, var(--surface) 96%, transparent);
  border-bottom: 1px solid var(--border);
}
.title {
  font-weight: 800;
  font-size: 12px;
  letter-spacing: 0.04em;
  color: var(--text-dim);
}
.chip {
  font-size: 11px;
  font-weight: 800;
  padding: 4px 8px;
  border-radius: 999px;
  border: 1px solid var(--border);
  color: var(--text-dim);
}
.chip[data-type='ok'] {
  color: #22c55e;
  border-color: #22c55e44;
  background: #22c55e22;
}
.chip[data-type='bad'] {
  color: #ef4444;
  border-color: #ef444444;
  background: #ef444422;
}
.chip[data-type='warn'] {
  color: #f59e0b;
  border-color: #f59e0b44;
  background: #f59e0b22;
}
.rp-body {
  overflow: auto;
  background: var(--term-bg);
}
.row {
  display: grid;
  grid-template-columns: 90px 1fr;
  gap: 8px;
  padding: 8px 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}
.row:last-child {
  border-bottom: none;
}
.tag {
  font-size: 11px;
  font-weight: 800;
  color: var(--text-dim);
}
.row[data-type='verdict'] .tag {
  color: #22c55e;
}
.row[data-type='error'] .tag {
  color: #ef4444;
}
.text pre {
  margin: 0;
  color: var(--term-fg);
  font-size: 13px;
  white-space: pre-wrap;
}
</style>
