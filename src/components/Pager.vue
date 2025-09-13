<template>
  <div class="pager">
    <button class="btn" :disabled="page <= 1" @click="$emit('update:page', page - 1)">Prev</button>
    <span class="p-meta">Page {{ page }} / {{ totalPages || 1 }}</span>
    <button class="btn" :disabled="page >= totalPages" @click="$emit('update:page', page + 1)">
      Next
    </button>
    <select v-model.number="localLimit" @change="$emit('update:limit', localLimit)">
      <option v-for="n in [10, 20, 30, 50]" :key="n" :value="n">{{ n }} / page</option>
    </select>
  </div>
</template>

<script>
export default {
  name: 'PagerComponent',
  emits: ['update:page', 'update:limit'],
  props: {
    page: { type: Number, default: 1 },
    total: { type: Number, default: 0 },
    limit: { type: Number, default: 20 },
  },
  data() {
    return { localLimit: this.limit }
  },
  computed: {
    totalPages() {
      return Math.max(1, Math.ceil(this.total / this.localLimit))
    },
  },
}
</script>

<style scoped>
.pager {
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
}
.p-meta {
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
</style>
