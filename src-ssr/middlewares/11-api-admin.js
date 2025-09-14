// src-ssr/middlewares/11-api-admin.js

async function requireAdmin(req) {
  if (!req.$auth?.user) return false
  try {
    const u = await req.$m.users.get(req.$auth.user.id)
    return !!u && u.active === 1 && u.role === 'admin'
  } catch {
    return false
  }
}

export default function () {
  return async (req, res, next) => {
    if (!req.url.startsWith('/api/admin')) return next()
    const send = (code, obj) => {
      res.statusCode = code
      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify(obj))
    }
    if (!(await requireAdmin(req))) return send(403, { error: 'forbidden' })
    const path = req.url.replace('/api/admin', '') || '/'
    const url = new URL('http://x' + path)
    const M = req.$m

    // GET /api/admin/users
    if (req.method === 'GET' && url.pathname === '/users') {
      const search = url.searchParams.get('search') || ''
      const page = Math.max(1, +(url.searchParams.get('page') || 1))
      const limit = Math.min(100, Math.max(1, +(url.searchParams.get('limit') || 20)))
      const data = await M.users.search({ search, page, limit })
      return send(200, { page, limit, total: data.total || 0, items: data.items || [] })
    }

    // POST /api/admin/users/:id/role
    if (req.method === 'POST' && /^\/users\/\d+\/role$/.test(url.pathname)) {
      const id = +url.pathname.split('/')[2]
      const { role } = req.body || {}
      if (!['user', 'admin'].includes(role)) return send(400, { error: 'invalid' })
      await M.users.update(id, { role })
      return send(200, { ok: true })
    }

    // POST /api/admin/users/:id/status
    if (req.method === 'POST' && /^\/users\/\d+\/status$/.test(url.pathname)) {
      const id = +url.pathname.split('/')[2]
      const { active } = req.body || {}
      await M.users.update(id, { active: active ? 1 : 0 })
      return send(200, { ok: true })
    }

    // GET /api/admin/stats
    if (req.method === 'GET' && url.pathname === '/stats') {
      const stats = await M.admin.stats()
      return send(200, stats)
    }

    return send(404, { error: 'not_found' })
  }
}
