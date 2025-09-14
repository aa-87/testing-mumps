<template>
  <div class="editor-wrap">
    <codemirror
      v-model="local"
      :extensions="exts"
      :autoFocus="true"
      class="cm-host"
      @ready="onReady"
      @update:modelValue="(v) => $emit('update:modelValue', v)"
    />
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import { Codemirror } from 'vue-codemirror'
import { EditorView, keymap, highlightActiveLine, drawSelection } from '@codemirror/view'
import { defaultKeymap, history, historyKeymap } from '@codemirror/commands'
import { searchKeymap } from '@codemirror/search'
import { oneDark } from '@codemirror/theme-one-dark'
import { javascript } from '@codemirror/lang-javascript'

export default defineComponent({
  name: 'CodeEditor',
  components: { Codemirror },
  props: {
    modelValue: { type: String, default: '' },
    dark: { type: Boolean, default: false },
  },
  emits: ['update:modelValue', 'run', 'save'],
  data() {
    return { local: this.modelValue, view: null }
  },
  watch: {
    modelValue(v) {
      if (v !== this.local) this.local = v
    },
  },
  computed: {
    exts() {
      const runKey = { key: 'Mod-Enter', run: () => (this.$emit('run'), true) }
      const saveKey = { key: 'Mod-s', run: () => (this.$emit('save'), true) }
      const base = [
        history(),
        keymap.of([runKey, saveKey, ...defaultKeymap, ...historyKeymap, ...searchKeymap]),
        drawSelection(),
        highlightActiveLine(),
        EditorView.lineWrapping,
        javascript(), // placeholder for M grammar later
      ]
      return this.dark ? [...base, oneDark] : base
    },
  },
  methods: {
    onReady(view) {
      this.view = view
    },
  },
})
</script>

<style scoped>
.editor-wrap {
  height: 100%;
}
.cm-host {
  height: 100%;
}
:deep(.cm-editor) {
  height: 100%;
  background: var(--term-bg);
  color: var(--term-fg);
  border-radius: 12px;
}
:deep(.cm-gutters) {
  background: color-mix(in srgb, var(--term-bg) 92%, black);
  border: none;
}
:deep(.cm-scroller) {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Courier New', monospace;
}
</style>
