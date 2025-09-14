<template>
  <article
    class="card"
    :data-key="item.id || item.slug"
    @click="$router.push({ name: 'practice-detail', params: { id: item.id || item.slug } })"
  >
    <div class="row" style="gap: 8px; align-items: center">
      <div class="pill" :class="item.difficulty.toLowerCase()">{{ item.difficulty }}</div>
      <h3 class="title">{{ capitalizeFirstLetter(item.slug.split('-').join(' ')) }}</h3>
      <code :title="item.title">{{ item.title.substring(0, 200) }}...</code>
    </div>
    <p class="meta">
      <span>{{ Number(item.acceptance ?? 0).toFixed(1) }}% acceptance</span>
      <span>·</span>
      <span>{{ item.tags?.join(', ') }}</span>
    </p>
  </article>
</template>

<script>
export default {
  name: 'ProblemCard',
  props: {
    item: { type: Object, required: true },
  },
  methods: {
    capitalizeFirstLetter(str) {
      if (typeof str !== 'string' || str.length === 0) {
        return str
      }
      return str.charAt(0).toUpperCase() + str.slice(1)
    },
  },
}
</script>

<style scoped>
.card {
  padding: 12px;
  border-radius: 16px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  cursor: pointer;
}
.card:hover {
  background: color-mix(in srgb, var(--surface) 98%, transparent);
}
.title {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
}
.meta {
  margin: 6px 0 0;
  color: var(--text-dim);
  font-size: 12px;
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
