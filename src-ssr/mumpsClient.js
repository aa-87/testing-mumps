// src-ssr/mumpsClient.js
// Lightweight client for your MUMPS JSON Web API.
// Configure env: MUMPS_BASE_URL (e.g. https://mumps-api.example), MUMPS_API_KEY (optional)

const BASE = process.env.MUMPS_BASE_URL || 'http://localhost:9080'
const API_KEY = process.env.MUMPS_API_KEY || ''

function timeoutFetch(url, opts = {}, ms = 5000) {
  const ac = new AbortController()
  const t = setTimeout(() => ac.abort(), ms)
  return fetch(url, { ...opts, signal: ac.signal }).finally(() => clearTimeout(t))
}

async function mpost(path, body = {}) {
  const res = await timeoutFetch(`${BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(API_KEY ? { 'x-api-key': API_KEY } : {}),
    },
    body: JSON.stringify(body),
  })
  const ct = (res.headers.get('content-type') || '').toLowerCase()
  const data = ct.includes('application/json') ? await res.json() : await res.text()
  if (!res.ok) {
    const msg = typeof data === 'string' ? data.slice(0, 200) : JSON.stringify(data).slice(0, 200)
    throw new Error(`MUMPS API ${res.status} ${path}: ${msg}`)
  }
  return data
}

/**
 * Expected M back-end endpoints (map to AUTHAPI^ or similar):
 *
 * POST /api/users/create        { email, password_hash } → { id, email, role, active, email_verified }
 * POST /api/users/get           { id }                   → { id, email, role, active, email_verified, email_verified_at, password_hash? }
 * POST /api/users/by-email      { email }                → { ...same as get... } | { error:'not_found' }
 * POST /api/users/update        { id, patch:{...} }      → { ok:true }
 * POST /api/users/search        { search, page, limit }  → { total, items:[...] }
 * POST /api/admin/stats         {}                       → { total, verified, active, admins }
 *
 * POST /api/resets/create       { jti, user_id, expires_at } → { id }
 * POST /api/resets/get          { jti, user_id }             → { id, used, expires_at } | { error:'not_found' }
 * POST /api/resets/mark-used    { id }                       → { ok:true }
 */

export function createMumpsClient() {
  return {
    users: {
      create: (email, password_hash) => mpost('/api/users/create', { email, password_hash }),
      get: (id) => mpost('/api/users/get', { id }),
      byEmail: (email) => mpost('/api/users/by-email', { email }),
      update: (id, patch) => mpost('/api/users/update', { id, patch }),
      search: (params) => mpost('/api/users/search', params),
    },
    resets: {
      create: (jti, user_id, expires_at) =>
        mpost('/api/resets/create', { jti, user_id, expires_at }),
      get: (jti, user_id) => mpost('/api/resets/get', { jti, user_id }),
      markUsed: (id) => mpost('/api/resets/mark-used', { id }),
    },
    admin: {
      stats: () => mpost('/api/admin/stats', {}),
    },
  }
}
