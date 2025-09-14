<template>
  <div :class="['sp', vertical ? 'sp-v' : 'sp-h']" ref="root">
    <div class="sp-pane sp-a" :style="paneAStyle"><slot name="a" /></div>
    <div class="sp-gutter" :class="{ dragging: isDrag }" @pointerdown="onDown" />
    <div class="sp-pane sp-b" :style="paneBStyle"><slot name="b" /></div>
  </div>
</template>

<script>
export default {
  name: 'SplitPane',
  props: {
    modelValue: { type: Number, default: 0.5 }, // ratio 0..1
    minA: { type: Number, default: 0.15 },
    minB: { type: Number, default: 0.2 },
    vertical: { type: Boolean, default: false }, // vertical = stacked (A top, B bottom)
  },
  data() {
    return { ratio: this.modelValue, isDrag: false, rect: null }
  },
  computed: {
    paneAStyle() {
      return this.vertical ? { height: `${this.ratio * 100}%` } : { width: `${this.ratio * 100}%` }
    },
    paneBStyle() {
      const r = 1 - this.ratio
      return this.vertical ? { height: `${r * 100}%` } : { width: `${r * 100}%` }
    },
  },
  watch: {
    modelValue(v) {
      this.ratio = v
    },
  },
  mounted() {
    /* noop */
  },
  methods: {
    onDown(e) {
      this.isDrag = true
      this.rect = this.$refs.root.getBoundingClientRect()
      e.currentTarget.setPointerCapture(e.pointerId)
      window.addEventListener('pointermove', this.onMove, { passive: true })
      window.addEventListener('pointerup', this.onUp, { passive: true, once: true })
    },
    onMove(e) {
      if (!this.isDrag || !this.rect) return
      let r
      if (this.vertical) {
        const y = Math.min(Math.max(e.clientY - this.rect.top, 0), this.rect.height)
        r = y / this.rect.height
      } else {
        const x = Math.min(Math.max(e.clientX - this.rect.left, 0), this.rect.width)
        r = x / this.rect.width
      }
      r = Math.min(1 - this.minB, Math.max(this.minA, r))
      this.ratio = r
      this.$emit('update:modelValue', r)
      window.dispatchEvent(new Event('resize')) // help Codemirror recompute layout
    },
    onUp() {
      this.isDrag = false
      window.removeEventListener('pointermove', this.onMove)
    },
  },
}
</script>

<style scoped>
.sp {
  display: grid;
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  overflow: hidden;
  background: var(--surface);
}
.sp-h {
  grid-template-columns: auto 10px 1fr;
}
.sp-v {
  grid-template-rows: auto 10px 1fr;
}
.sp-pane {
  min-width: 0;
  min-height: 0;
}
.sp-gutter {
  background: color-mix(in srgb, var(--surface) 92%, transparent);
  cursor: col-resize;
  position: relative;
}
.sp-v .sp-gutter {
  cursor: row-resize;
}
.sp-gutter::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    transparent 0,
    transparent 40%,
    var(--border) 40%,
    var(--border) 60%,
    transparent 60%,
    transparent 100%
  );
  opacity: 0.6;
}
.sp-v .sp-gutter::after {
  background: linear-gradient(
    180deg,
    transparent 0,
    transparent 40%,
    var(--border) 40%,
    var(--border) 60%,
    transparent 60%,
    transparent 100%
  );
}
.sp-gutter.dragging {
  background: color-mix(in srgb, var(--surface) 98%, transparent);
}
</style>
