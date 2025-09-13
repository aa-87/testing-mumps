const API_BASE = '/api/problems' // mapped to ^PROBAPI

function toQS(obj) {
  const p = []
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null || v === '') continue
    if (Array.isArray(v))
      v.forEach((x) => p.push(`${encodeURIComponent(k)}=${encodeURIComponent(x)}`))
    else p.push(`${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
  }
  return p.length ? `?${p.join('&')}` : ''
}

// GET /api/problems?search=&difficulty=Easy&difficulty=Hard&sort=newest&page=1&limit=20
export async function fetchProblems(params = {}) {
  const res = await fetch(`${API_BASE}${toQS(params)}`, { headers: { Accept: 'application/json' } })
  if (!res.ok) throw new Error(`API ${res.status}`)
  return res.json()
}

// GET /api/problems/:idOrSlug
export async function fetchProblem(idOrSlug) {
  const res = await fetch(`${API_BASE}/${encodeURIComponent(idOrSlug)}`, {
    headers: { Accept: 'application/json' },
  })
  if (!res.ok) throw new Error(`API ${res.status}`)
  return res.json()
}

// GET /api/problems/facets
export async function fetchFacets() {
  const res = await fetch(`${API_BASE}/facets`, { headers: { Accept: 'application/json' } })
  if (!res.ok) throw new Error(`API ${res.status}`)
  return res.json()
}
