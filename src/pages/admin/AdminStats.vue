<template>
  <div class="page">
    <div class="cards">
      <div class="card surface">
        <div class="h">Total users</div>
        <div class="v">{{ stats.total }}</div>
      </div>
      <div class="card surface">
        <div class="h">Verified</div>
        <div class="v">{{ stats.verified }}</div>
      </div>
      <div class="card surface">
        <div class="h">Active</div>
        <div class="v">{{ stats.active }}</div>
      </div>
      <div class="card surface">
        <div class="h">Admins</div>
        <div class="v">{{ stats.admins }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { adminApi } from '../../api/admin'
export default {
  name: 'AdminStats',
  data() {
    return { stats: { total: 0, verified: 0, active: 0, admins: 0 } }
  },
  async mounted() {
    this.stats = await adminApi.stats()
  },
}
</script>

<style scoped>
.page {
  max-width: 980px;
  margin: 0 auto;
  padding: 12px 16px;
}
.cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.card {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 12px;
}
.h {
  color: var(--text-dim);
  font-size: 12px;
}
.v {
  font-weight: 900;
  font-size: 28px;
}
@media (max-width: 860px) {
  .cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
