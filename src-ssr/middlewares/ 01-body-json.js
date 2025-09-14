// Tiny JSON body parser with a size cap (avoid huge payloads)
export default function () {
  return async (req, res, next) => {
    if (req.method === 'GET' || req.method === 'HEAD') return next()
    const ct = (req.headers['content-type'] || '').toLowerCase()
    if (!ct.includes('application/json')) return next()
    try {
      let body = ''
      let len = 0
      req.on('data', (chunk) => {
        len += chunk.length
        if (len > 1_000_000) {
          // 1MB
          req.destroy()
          return
        }
        body += chunk
      })
      req.on('end', () => {
        try {
          req.body = body ? JSON.parse(body) : {}
        } catch {
          req.body = {}
        }
        next()
      })
    } catch (e) {
      next(e)
    }
  }
}
