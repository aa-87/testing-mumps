<template>
  <div class="page">
    <!-- Sticky masthead -->
    <div class="mast surface">
      <div class="left">
        <button class="btn" @click="$router.back()">←</button>
        <div class="meta">
          <div class="title">{{ problem?.slug || 'Loading…' }}</div>
          <div class="sub">
            <span class="pill" :class="(problem?.difficulty || '').toLowerCase()">{{
              problem?.difficulty
            }}</span>
            <span class="dot">•</span>
            <span>{{ (problem?.acceptance ?? 0).toFixed(1) }}% acceptance</span>
            <span v-if="problem?.tags?.length" class="dot">•</span>
            <span v-if="problem?.tags?.length">{{ problem.tags.join(', ') }}</span>
          </div>
        </div>
      </div>
      <div class="right">
        <button class="btn" @click="resetCode" :disabled="busy">Reset</button>
        <button class="btn" @click="toggleFullscreen">
          {{ isFullscreen ? 'Exit Fullscreen' : 'Fullscreen' }}
        </button>
        <button class="btn" @click="onRun" :disabled="busy">Run (⌘/Ctrl+Enter)</button>
        <button class="btn btn-primary" @click="onSubmit" :disabled="busy">Submit</button>
      </div>
    </div>

    <!-- MAIN: nested Quasar splitters -->
    <div class="main">
      <!-- Outer: statement (before) | workspace (after) -->
      <q-splitter v-model="splitLR" :unit="'%'" :limits="[24, 80]" class="split-root">
        <!-- LEFT: Statement -->
        <template #before>
          <div class="pane-left surface">
            <div class="tabs">
              <button :class="['tab', { active: tab === 'desc' }]" @click="tab = 'desc'">
                Description
              </button>
              <button :class="['tab', { active: tab === 'examples' }]" @click="tab = 'examples'">
                Examples
              </button>
              <button class="tab" disabled>Discussion</button>
            </div>
            <div class="content">
              <div v-show="tab === 'desc'" class="desc" v-html="problem?.description"></div>
              <div v-show="tab === 'examples'">
                <div v-if="samples.length" class="ex-list">
                  <div v-for="(s, i) in samples" :key="i" class="ex-item">
                    <div class="ex-head">Example {{ i + 1 }}</div>
                    <pre class="ex"><code>{{ s }}</code></pre>
                  </div>
                </div>
                <div v-else class="muted">No examples parsed yet.</div>
              </div>
            </div>
          </div>
        </template>

        <!-- RIGHT: Workspace -->
        <template #after>
          <div class="pane-right" ref="rightRoot">
            <div class="work surface">
              <!-- Toolbar -->
              <div class="toolbar">
                <div class="group">
                  <span class="label">Testcase</span>
                  <select v-model="testcaseMode">
                    <option value="sample">Sample</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>
                <div class="group">
                  <span class="hint">Autosaved</span>
                  <span v-if="busy" class="busy-dot" aria-label="busy"></span>
                </div>
              </div>

              <!-- Inner vertical splitter: Editor (before) | Results (after) -->
              <q-splitter
               horizontal
                v-model="splitTB"
                :unit="'%'"
                :limits="[35, 78]"
                orientation="vertical"
                class="split-inner"
              >
                <template #before>
                  <div class="editor-wrap">
                    <CodeEditor v-model="code" :dark="isDark" @run="onRun" @save="onSave" />
                    <div v-if="testcaseMode === 'custom'" class="custom">
                      <label>Custom Input</label>
                      <textarea v-model="customInput" spellcheck="false" />
                    </div>
                  </div>
                </template>

                <template #after>
                  <ResultPanel :rows="rows" :verdict="verdict" />
                </template>
              </q-splitter>
            </div>
          </div>
        </template>
      </q-splitter>
    </div>

    <!-- Footer -->
    <div class="footer-basic"><a href="#">Docs</a><a href="#">Contact</a></div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import { Dark } from 'quasar'
import gsap from 'gsap'
import CodeEditor from '../../components/CodeEditor.vue'
import ResultPanel from '../../components/ResultPanel.vue'
import { fetchProblem } from '../../api/client'
import { connectProblemSession } from '../../ws/service'

export default defineComponent({
  name: 'PracticeDetail',
  components: { CodeEditor, ResultPanel },
  props: { id: { type: String, required: true } },
  data() {
    return {
      isDark: Dark.isActive,
      problem: null,
      samples: [],
      tab: 'desc',
      splitLR: 46, // percentage for LEFT panel
      splitTB: 64, // percentage for TOP editor panel
      code: '',
      customInput: '',
      testcaseMode: 'sample',
      rows: [],
      verdict: '',
      busy: false,
      ws: null,
      isFullscreen: false,
    }
  },
  async mounted() {
    const data = await fetchProblem(this.id)
    this.problem = data
    document.title = `${data.title} — MUMPS.IO`
    this.samples = this.extractExamples(data.description)

    this.code = localStorage.getItem(this.key()) || this.template()

    // GSAP micro-motions
    gsap.from('.mast', { y: -8, opacity: 0, duration: 0.45, ease: 'power2.out' })
    gsap.from('.tabs .tab', {
      y: 6,
      opacity: 0,
      duration: 0.35,
      ease: 'power2.out',
      stagger: 0.04,
      delay: 0.05,
    })
    gsap.from('.work', { y: 8, opacity: 0, duration: 0.45, ease: 'power2.out', delay: 0.08 })

    window.addEventListener('theme-change', this.onTheme, { passive: true })
  },
  beforeUnmount() {
    window.removeEventListener('theme-change', this.onTheme)
    try {
      this.ws && this.ws.close()
    } catch {
      return
    }
  },
  methods: {
    onTheme() {
      this.isDark = Dark.isActive
    },
    key() {
      return `mumpsio:code:${this.problem?.id || this.id}`
    },
    onSave() {
      localStorage.setItem(this.key(), this.code)
    },
    resetCode() {
      this.code = this.template()
      this.onSave()
    },

    async onRun() {
      this.onSave()
      await this.ensureWS()
      this.rows = []
      this.verdict = ''
      this.busy = true
      this.ws.send(
        JSON.stringify({
          op: 'run',
          problemId: this.problem?.id || this.id,
          code: this.code,
          input: this.testcaseMode === 'custom' ? this.customInput : undefined,
        }),
      )
    },
    async onSubmit() {
      this.onSave()
      await this.ensureWS()
      this.rows = []
      this.verdict = ''
      this.busy = true
      this.ws.send(
        JSON.stringify({
          op: 'submit',
          problemId: this.problem?.id || this.id,
          code: this.code,
        }),
      )
    },
    async ensureWS() {
      if (this.ws && this.ws.readyState === 1) return
      this.ws = connectProblemSession(this.problem?.id || this.id)
      this.ws.addEventListener('open', () => {})
      this.ws.addEventListener('close', () => {
        this.busy = false
      })
      this.ws.addEventListener('error', () => {
        this.busy = false
        this.push('error', 'WebSocket error')
      })
      this.ws.addEventListener('message', (ev) => {
        let m = {}
        try {
          m = JSON.parse(ev.data)
        } catch {
          return
        }
        this.onJudge(m)
      })
    },
    onJudge(m) {
      switch (m.type) {
        case 'queue':
          this.push('status', `In queue… position ${m.position}`)
          break
        case 'compile:start':
          this.push('status', 'Compiling…')
          break
        case 'compile:ok':
          this.push('status', `Compile OK (${m.time}ms)`)
          break
        case 'run:case':
          this.push('case', `Case ${m.case}/${m.total}: ${m.status}  · ${m.time}ms · ${m.memory}MB`)
          break
        case 'done':
          this.verdict = `${m.verdict}  · ${m.runtime ?? '?'}ms · ${m.memory ?? '?'}MB`
          this.push('verdict', this.verdict)
          this.busy = false
          break
        case 'error':
          this.push('error', m.message || 'Error')
          this.busy = false
          break
      }
    },
    push(type, text) {
      this.rows.push({ type, text })
    },
    async toggleFullscreen() {
      const el = this.$refs.rightRoot
      if (!document.fullscreenElement) {
        await el.requestFullscreen().catch(() => {})
        this.isFullscreen = true
      } else {
        await document.exitFullscreen().catch(() => {})
        this.isFullscreen = false
      }
    },
    template() {
      return [
        '; M template',
        'MAIN ;',
        '  NEW I,S SET S=0',
        '  FOR I=1:1:5 SET S=S+I',
        '  WRITE "Sum=",S,!',
        '  QUIT',
      ].join('\n')
    },
    extractExamples(html) {
      if (!html) return []
      const txt = html.replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]*>/g, '\n')
      const blocks = txt.split(/Example\s*\d*[:\n]/i).slice(1)
      return blocks.slice(0, 3).map((s) => s.trim().split('\n').slice(0, 20).join('\n'))
    },
  },
})
</script>

<style scoped>
/* Layout */
.page {
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 12px;
  min-height: 100svh;
  max-width: 1240px;
  margin: 0 auto;
  padding: 12px 16px;
}
.main {
  min-height: 0;
} /* allow child to fill available height */
.split-root,
.split-inner {
  height: 100%;
} /* make both splitters fill the area */

/* Ensure Quasar panels can actually shrink/scroll */
:deep(.q-splitter__panel) {
  min-width: 0;
  min-height: 0;
}

/* Masthead */
.mast {
  position: sticky;
  top: 0;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: color-mix(in srgb, var(--surface) 96%, transparent);
}
.left {
  display: flex;
  gap: 10px;
  align-items: center;
}
.meta .title {
  font-weight: 800;
  font-size: 18px;
}
.meta .sub {
  display: flex;
  gap: 8px;
  align-items: center;
  color: var(--text-dim);
  font-size: 12px;
}
.pill {
  font-size: 11px;
  font-weight: 800;
  padding: 4px 8px;
  border-radius: 999px;
  border: 1px solid var(--border);
}
.pill.easy {
  background: #0e7a3b22;
  color: #26d07c;
  border-color: #26d07c33;
}
.pill.medium {
  background: #9a7d1222;
  color: #facc15;
  border-color: #facc1533;
}
.pill.hard {
  background: #7a121222;
  color: #ef4444;
  border-color: #ef444433;
}
.dot {
  opacity: 0.6;
}
.right {
  display: flex;
  gap: 10px;
  align-items: center;
}

/* Left panel */
.pane-left {
  height: 100%;
  display: grid;
  grid-template-rows: auto 1fr;
}
.tabs {
  display: flex;
  gap: 6px;
  padding: 8px;
  border-bottom: 1px solid var(--border);
}
.tab {
  padding: 8px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 92%, transparent);
  color: var(--text-dim);
  font-weight: 800;
  font-size: 12px;
  letter-spacing: 0.02em;
}
.tab.active {
  color: var(--text);
  background: color-mix(in srgb, var(--surface) 84%, transparent);
}
.tab:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.content {
  padding: 12px;
  overflow: auto;
}
.desc {
  font-size: 14px;
  line-height: 1.55;
  color: var(--text);
}
.ex-list {
  display: grid;
  gap: 10px;
}
.ex-item {
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: hidden;
}
.ex-head {
  padding: 8px 10px;
  font-weight: 800;
  color: var(--text-dim);
  background: color-mix(in srgb, var(--surface) 96%, transparent);
  border-bottom: 1px solid var(--border);
}
.ex {
  margin: 0;
  padding: 10px;
  background: var(--term-bg);
  color: var(--term-fg);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Courier New';
  font-size: 13px;
}

/* Right panel */
.pane-right {
  height: 100%;
  min-height: 0;
}
.work {
  height: 100%;
  display: grid;
  grid-template-rows: auto 1fr;
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: hidden;
}
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 8px 10px;
  border-bottom: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 96%, transparent);
}
.group {
  display: flex;
  gap: 8px;
  align-items: center;
}
.label {
  color: var(--text-dim);
  font-size: 12px;
}
select {
  padding: 8px 10px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.busy-dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #fbbf24;
  display: inline-block;
  box-shadow: 0 0 0 4px rgba(251, 191, 36, 0.12);
}

.editor-wrap {
  height: 100%;
  display: grid;
  grid-template-rows: 1fr auto;
  gap: 8px;
  padding: 8px;
}
.custom label {
  display: block;
  font-weight: 800;
  color: var(--text-dim);
  font-size: 12px;
  margin-bottom: 6px;
}
.custom textarea {
  width: 100%;
  min-height: 84px;
  resize: vertical;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--term-bg);
  color: var(--term-fg);
  padding: 8px 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Courier New';
}

.footer-basic {
  border-top: 1px solid var(--border);
  padding: 12px 0;
  display: flex;
  gap: 14px;
  justify-content: center;
}
.footer-basic a {
  color: var(--text-dim);
  text-decoration: none;
  font-size: 13px;
}
.footer-basic a:hover {
  color: var(--text);
  text-decoration: underline;
}

@media (max-width: 1100px) {
  .mast {
    flex-wrap: wrap;
  }
  .right {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
