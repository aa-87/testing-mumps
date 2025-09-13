<template>
  <div class="filterbar surface" ref="bar">
    <input
      v-model.trim="local.search"
      @input="onSearch"
      type="search"
      placeholder="Search problems (title, tags)…"
    />
    <div class="chips">
      <button :class="['chip', { active: isDiff('Easy') }]" @click="toggleDiff('Easy')">
        Easy
      </button>
      <button :class="['chip', { active: isDiff('Medium') }]" @click="toggleDiff('Medium')">
        Medium
      </button>
      <button :class="['chip', { active: isDiff('Hard') }]" @click="toggleDiff('Hard')">
        Hard
      </button>
    </div>
    <select v-model="local.sort" @change="$emit('change', payload())">
      <option value="newest">Newest</option>
      <option value="difficulty">Difficulty</option>
      <option value="title">Title</option>
      <option value="hot">Hot</option>
    </select>
  </div>
</template>

<script>
import gsap from 'gsap'
export default {
  name: 'FilterBar',
  emits: ['change'],
  props: {
    value: { type: Object, default: () => ({ search: '', difficulty: [], sort: 'newest' }) },
  },
  data() {
    return {
      local: {
        search: this.value.search || '',
        difficulty: [...(this.value.difficulty || [])],
        sort: this.value.sort || 'newest',
      },
      ttt: null,
    }
  },
  mounted() {
    gsap.from(this.$refs.bar, { y: 12, opacity: 0, duration: 0.45, ease: 'power2.out' })
  },
  methods: {
    isDiff(d) {
      return this.local.difficulty.includes(d)
    },
    toggleDiff(d) {
      const i = this.local.difficulty.indexOf(d)
      i >= 0 ? this.local.difficulty.splice(i, 1) : this.local.difficulty.push(d)
      this.$emit('change', this.payload())
    },
    onSearch() {
      clearTimeout(this.ttt)
      this.ttt = setTimeout(() => this.$emit('change', this.payload()), 250)
    },
    payload() {
      return { search: this.local.search, difficulty: this.local.difficulty, sort: this.local.sort }
    },
  },
}
</script>

<style scoped>
.filterbar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 16px;
}
input[type='search'] {
  flex: 1;
  min-width: 200px;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
select {
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.chips {
  display: flex;
  gap: 8px;
}
.chip {
  padding: 8px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-dim);
  font-weight: 700;
}
.chip.active {
  color: var(--text);
  background: color-mix(in srgb, var(--surface) 92%, transparent);
}
</style>
