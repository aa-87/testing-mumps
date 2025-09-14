<template>
  <div class="page">
    <div class="head surface">
      <div class="title">Users</div>
      <div class="tools">
        <input
          type="search"
          v-model.trim="search"
          placeholder="Search email…"
          @input="debounced()"
        />
        <select v-model.number="limit" @change="load">
          <option v-for="n in [10, 20, 50, 100]" :key="n" :value="n">{{ n }}/page</option>
        </select>
      </div>
    </div>

    <div class="list surface">
      <div class="row head">
        <div>ID</div>
        <div>Email</div>
        <div>Role</div>
        <div>Verified</div>
        <div>Active</div>
        <div>Actions</div>
      </div>
      <div v-for="u in items" :key="u.id" class="row">
        <div>{{ u.id }}</div>
        <div>{{ u.email }}</div>
        <div>
          <span class="pill" :class="u.role">{{ u.role }}</span>
        </div>
        <div>
          <span :class="['mark', u.email_verified ? 'ok' : 'no']">{{
            u.email_verified ? 'Yes' : 'No'
          }}</span>
        </div>
        <div>
          <span :class="['mark', u.active ? 'ok' : 'no']">{{ u.active ? 'Yes' : 'No' }}</span>
        </div>
        <div class="actions">
          <button class="btn" @click="toggleRole(u)">
            {{ u.role === 'admin' ? 'Make user' : 'Make admin' }}
          </button>
          <button class="btn" @click="toggleActive(u)">
            {{ u.active ? 'Deactivate' : 'Activate' }}
          </button>
        </div>
      </div>
    </div>

    <div class="pager">
      <button
        class="btn"
        :disabled="page <= 1"
        @click="
          page--
          load()
        "
      >
        Prev
      </button>
      <span>Page {{ page }} / {{ totalPages }}</span>
      <button
        class="btn"
        :disabled="page >= totalPages"
        @click="
          page++
          load()
        "
      >
        Next
      </button>
    </div>
  </div>
</template>

<script>
import { adminApi } from '../../api/admin'
export default {
  name: 'AdminUsers',
  data() {
    return { items: [], total: 0, page: 1, limit: 20, search: '', ttt: null }
  },
  computed: {
    totalPages() {
      return Math.max(1, Math.ceil(this.total / this.limit))
    },
  },
  mounted() {
    this.load()
  },
  methods: {
    debounced() {
      clearTimeout(this.ttt)
      this.ttt = setTimeout(() => {
        this.page = 1
        this.load()
      }, 250)
    },
    async load() {
      const { items, total } = await adminApi.users({
        page: this.page,
        limit: this.limit,
        search: this.search,
      })
      this.items = items || []
      this.total = total || 0
    },
    async toggleRole(u) {
      await adminApi.setRole(u.id, u.role === 'admin' ? 'user' : 'admin')
      this.load()
    },
    async toggleActive(u) {
      await adminApi.setStat(u.id, u.active ? 0 : 1)
      this.load()
    },
  },
}
</script>

<style scoped>
.page {
  max-width: 980px;
  margin: 0 auto;
  padding: 12px 16px;
  display: grid;
  gap: 12px;
}
.head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
}
.title {
  font-weight: 800;
}
.tools {
  display: flex;
  gap: 8px;
  align-items: center;
}
.tools input,
.tools select {
  padding: 8px 10px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.list {
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: hidden;
}
.row {
  display: grid;
  grid-template-columns: 80px 1fr 120px 110px 110px 260px;
  gap: 10px;
  padding: 8px 10px;
  border-bottom: 1px solid var(--border);
  align-items: center;
}
.row.head {
  background: color-mix(in srgb, var(--surface) 96%, transparent);
  font-weight: 800;
}
.pill {
  font-size: 11px;
  font-weight: 800;
  padding: 4px 8px;
  border-radius: 999px;
  border: 1px solid var(--border);
  color: var(--text-dim);
}
.pill.admin {
  color: #a78bfa;
  border-color: #a78bfa44;
  background: #a78bfa22;
}
.mark.ok {
  color: #22c55e;
}
.mark.no {
  color: #ef4444;
}
.actions {
  display: flex;
  gap: 8px;
}
.pager {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  align-items: center;
}
</style>
