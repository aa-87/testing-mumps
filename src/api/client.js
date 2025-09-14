// src/api/client.js
// POST-only client for ^PROBAPI
// Endpoints (server maps):
//   POST /api/problems/list    -> LIST^PROBAPI(.IN,.OUT)
//   POST /api/problems/get     -> GET^PROBAPI(.IN,.OUT)
//   POST /api/problems/facets  -> FACETS^PROBAPI(.IN,.OUT)

const API_BASE = 'http://192.168.0.131:7777/api/problems'

/** Internal: POST JSON helper */
async function postJSON(path, body = {}, fetchOptions = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(body),
    ...fetchOptions,
  })

  if (!res.ok) {
    const text = await res.text().catch(() => '')
    throw new Error(`API ${res.status}: ${text.slice(0, 200)}`)
  }
  // Some servers may not set content-type perfectly; be forgiving.
  const ct = (res.headers.get('content-type') || '').toLowerCase()
  if (ct.includes('application/json')) return res.json()
  const raw = await res.text()
  try {
    return JSON.parse(raw)
  } catch {
    return raw
  }
}

/** Convert difficulty array → flags expected by M backend */
function toDifficultyFlags(diffs) {
  const flags = {}
  if (Array.isArray(diffs)) {
    diffs.forEach((d) => {
      const k = String(d || '').trim()
      if (k === 'Easy' || k === 'Medium' || k === 'Hard') flags[k] = 1
    })
  } else if (diffs && typeof diffs === 'object') {
    // pass-through if caller already provided as flags
    ;['Easy', 'Medium', 'Hard'].forEach((k) => {
      if (diffs[k]) flags[k] = 1
    })
  }
  return flags
}

/**
 * List problems with search/filter/sort/pagination.
 * @param {Object} params
 * @param {string} [params.search]
 * @param {'newest'|'title'|'difficulty'|'hot'} [params.sort='newest']
 * @param {number} [params.page=1]
 * @param {number} [params.limit=20]
 * @param {Array<string>|Object} [params.difficulty] // ['Easy','Medium'] or {Easy:1, Medium:1}
 * @param {Object} [fetchOptions] // e.g., { signal }
 */
export async function fetchProblems(params = {}, fetchOptions = {}) {
  const { search = '', sort = 'newest', page = 1, limit = 20, difficulty = [] } = params

  const payload = { search, sort, page, limit }
  const flags = toDifficultyFlags(difficulty)
  if (Object.keys(flags).length) payload.difficulty = flags

  return postJSON('/list', payload, fetchOptions)
}

/**
 * Get a single problem by id OR slug.
 * @param {string|number} idOrSlug
 * @param {Object} [fetchOptions]
 */
export async function fetchProblem(idOrSlug, fetchOptions = {}) {
  if (idOrSlug == null) throw new Error('fetchProblem: idOrSlug is required')

  let payload
  if (typeof idOrSlug === 'number' || (typeof idOrSlug === 'string' && /^\d+$/.test(idOrSlug))) {
    payload = { id: Number(idOrSlug) }
  } else {
    payload = { slug: String(idOrSlug) }
  }
  return postJSON('/get', payload, fetchOptions)
}

/**
 * Get facet counts (difficulty & tags).
 * @param {Object} [fetchOptions]
 */
export async function fetchFacets(fetchOptions = {}) {
  return postJSON('/facets', {}, fetchOptions)
}
