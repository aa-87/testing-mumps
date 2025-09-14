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

      <!-- Results summary with animated counter -->
      <div class="row" style="justify-content: space-between; align-items: center">
        <div class="text-caption" style="color: var(--text-dim)">
          Found <span ref="totalEl">{{ uiTotal }}</span> problem<span v-if="(total || 0) !== 1"
            >s</span
          >
        </div>
        <Pager
          :page="page"
          :total="total"
          :limit="limit"
          @update:page="(p) => ((page = p), fetchList())"
          @update:limit="(l) => ((limit = l), (page = 1), fetchList())"
        />
      </div>

      <!-- Grid (note the ref) -->
      <div class="modules" ref="grid">
        <ProblemCard v-for="p in items" :key="p.id || p.slug" :item="p" />
      </div>
    </div>

    <div class="footer-basic">
      <a href="#">Pricing</a><a href="#">Docs</a><a href="#">Privacy</a><a href="#">Terms</a
      ><a href="#">Contact</a>
    </div>
  </div>
</template>

<script>
import { defineComponent, nextTick } from 'vue'
import gsap from 'gsap'
import Flip from 'gsap/Flip'
import FilterBar from '../../components/FilterBar.vue'
import Pager from '../../components/Pager.vue'
import ProblemCard from '../../components/ProblemCard.vue'
import { fetchProblems } from '../../api/client'

gsap.registerPlugin(Flip)

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
      uiTotal: 0,
      firstPaint: true,
    }
  },
  mounted() {
    this.hydrateFromURL()
    this.fetchList(/*animate*/ false)
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

    animateCounter(fromVal, toVal) {
      const obj = { v: fromVal }
      gsap.to(obj, {
        v: toVal,
        duration: 0.5,
        ease: 'power2.out',
        onUpdate: () => {
          this.uiTotal = Math.round(obj.v)
        },
      })
    },

    async fetchList(animate = true) {
      this.pushURL()

      // Take FLIP snapshot BEFORE data change
      let state = null
      if (!this.firstPaint && animate && this.$refs.grid) {
        const cards = Array.from(this.$refs.grid.querySelectorAll('.card'))
        if (cards.length) state = Flip.getState(cards)
      }

      const res = await fetchProblems({
        search: this.filters.search,
        difficulty: this.filters.difficulty,
        sort: this.filters.sort,
        page: this.page,
        limit: this.limit,
      })
      const prevTotal = this.total
      this.total = res.total || 0
      this.items = res.items || []
      await nextTick()

      // Animate counter even on first paint for a nice touch
      this.animateCounter(this.firstPaint ? 0 : prevTotal, this.total)

      if (this.firstPaint) {
        // Staggered entrance on first paint
        const cards = Array.from(this.$refs.grid.querySelectorAll('.card'))
        gsap.from(cards, { y: 10, opacity: 0, duration: 0.45, ease: 'power2.out', stagger: 0.03 })
        this.firstPaint = false
        return
      }

      if (state) {
        // FLIP reflow on subsequent updates (filters/paging)
        const cardsAfter = Array.from(this.$refs.grid.querySelectorAll('.card'))
        Flip.from(
          state,
          {
            duration: 0.5,
            ease: 'power2.inOut',
            absolute: true,
            stagger: 0.01,
            onEnter: (elements) =>
              gsap.fromTo(
                elements,
                { opacity: 0, y: 8 },
                { opacity: 1, y: 0, duration: 0.3, ease: 'power2.out' },
              ),
            onLeave: (elements) =>
              gsap.to(elements, { opacity: 0, y: -8, duration: 0.25, ease: 'power2.in' }),
          },
          cardsAfter,
        )
      }
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
/* help the GPU with frequent transforms in FLIP */
.card {
  will-change: transform, opacity;
}
</style>
