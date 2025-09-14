import { randomBytes } from 'node:crypto'
const CSRF_COOKIE = 'csrf'

// Set CSRF cookie (lax) and validate unsafe methods (POST/PUT/PATCH/DELETE)
export default function () {
  return (req, res, next) => {
    if (!req.cookies?.[CSRF_COOKIE]) {
      const token = randomBytes(16).toString('hex')
      const secure = process.env.NODE_ENV === 'production'
      res.cookie(CSRF_COOKIE, token, { httpOnly: false, sameSite: 'lax', secure, path: '/' })
    }
    const method = req.method.toUpperCase()
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
      const sent = req.headers['x-csrf-token'] || ''
      const cookie = req.cookies?.[CSRF_COOKIE] || ''
      if (!sent || sent !== cookie) {
        res.statusCode = 403
        return res.end(JSON.stringify({ error: 'csrf' }))
      }
    }
    next()
  }
}
