<template>
  <div class="container">
    <div class="header">
      <button class="btn" @click="$router.back()">← Back</button>
      <div class="brand gradient-text" style="justify-self: center">
        {{ problem?.title || 'Loading…' }}
      </div>
      <div style="justify-self: end">
        <button class="btn" @click="$router.push('/practice')">All problems</button>
      </div>
    </div>

    <div class="content" v-if="problem">
      <div class="surface" style="padding: 16px">
        <div class="row" style="gap: 10px; align-items: center">
          <div class="pill" :class="problem.difficulty.toLowerCase()">{{ problem.difficulty }}</div>
          <div class="text-caption" style="color: var(--text-dim)">
            {{ Number(problem.acceptance ?? 0).toFixed(1) }}% acceptance
          </div>
          <div class="text-caption" style="color: var(--text-dim)">
            · {{ problem.tags?.join(', ') }}
          </div>
        </div>
        <h1 style="margin: 10px 0 6px; font-size: 22px">{{ problem.title }}</h1>
        <p class="sub" v-html="problem.description"></p>
      </div>
    </div>

    <div class="footer-basic"><a href="#">Docs</a><a href="#">Contact</a></div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import { fetchProblem } from '../../api/client'

export default defineComponent({
  name: 'PracticeDetail',
  props: { id: { type: String, required: true } },
  data() {
    return { problem: null }
  },
  async mounted() {
    const data = await fetchProblem(this.id)
    this.problem = data
    document.title = `${data.title} — MUMPS.IO`
  },
})
</script>

<style scoped>
.row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.pill {
  font-size: 11px;
  font-weight: 700;
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
</style>
