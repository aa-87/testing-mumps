<template>
  <div class="container">
    <div class="header">
      <div class="brand gradient-text">Practice · MUMPS.IO</div>
      <div style="justify-self: end; display: flex; gap: 10px">
        <button class="btn" @click="$router.push('/')">Home</button>
      </div>
    </div>

    <div class="content">
      <FilterBar :value="filters" @change="onFilters" />

      <div class="row" style="justify-content: space-between; align-items: center">
        <div class="text-caption" style="color: var(--text-dim)">
          Found {{ total }} problem<span v-if="total !== 1">s</span>
        </div>
        <Pager
          :page="page"
          :total="total"
          :limit="limit"
          @update:page="(p) => ((page = p), fetchList())"
          @update:limit="(l) => ((limit = l), (page = 1), fetchList())"
        />
      </div>

      <div class="modules">
        <ProblemCard v-for="p in items" :key="p.id" :item="p" />
      </div>
    </div>

    <div class="footer-basic">
      <a href="#">Pricing</a><a href="#">Docs</a><a href="#">Privacy</a><a href="#">Terms</a
      ><a href="#">Contact</a>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import FilterBar from '../../components/FilterBar.vue'
import Pager from '../../components/Pager.vue'
import ProblemCard from '../../components/ProblemCard.vue'
import { fetchProblems } from '../../api/client'

export default defineComponent({
  name: 'PracticeIndex',
  components: { FilterBar, Pager, ProblemCard },
  data() {
    return {
      filters: { search: '', difficulty: [], sort: 'newest' },
      page: 1,
      limit: 20,
      total: 0,
      items: [],
    }
  },
  mounted() {
    this.hydrateFromURL()
    this.fetchList()
  },
  methods: {
    hydrateFromURL() {
      const q = new URLSearchParams(location.search)
      this.filters.search = q.get('search') || ''
      this.filters.difficulty = q.getAll('difficulty')
      this.filters.sort = q.get('sort') || 'newest'
      this.page = +(q.get('page') || 1)
      this.limit = +(q.get('limit') || 20)
    },
    pushURL() {
      const q = new URLSearchParams()
      if (this.filters.search) q.set('search', this.filters.search)
      this.filters.difficulty.forEach((d) => q.append('difficulty', d))
      if (this.filters.sort) q.set('sort', this.filters.sort)
      q.set('page', this.page)
      q.set('limit', this.limit)
      history.replaceState(null, '', `/practice?${q.toString()}`)
    },
    onFilters(payload) {
      this.filters = payload
      this.page = 1
      this.fetchList()
    },
    async fetchList() {
      this.pushURL()
      const res = await fetchProblems({
        search: this.filters.search,
        difficulty: this.filters.difficulty,
        sort: this.filters.sort,
        page: this.page,
        limit: this.limit,
      })
      this.total = res.total || 0
      this.items = res.items || []
    },
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
.modules {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}
@media (min-width: 1100px) {
  .modules {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>
