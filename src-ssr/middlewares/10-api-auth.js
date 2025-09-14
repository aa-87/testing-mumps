// src-ssr/middlewares/10-api-auth.js
import argon2 from 'argon2'
import jwt from 'jsonwebtoken'
import { nanoid } from 'nanoid'

//const ACCESS_COOKIE = 'sid'
const SECRET = process.env.JWT_SECRET || 'dev-secret-change-me'
const RESET_TTL = 60 * 60 * 1 // 1h
//const VERIFY_TTL = 60 * 60 * 24 // 24h

function sign(payload, ttlSec, opts = {}) {
  return jwt.sign(payload, SECRET, { expiresIn: ttlSec, jwtid: opts.jti })
}
function verifyToken(token) {
  try {
    return jwt.verify(token, SECRET)
  } catch {
    return null
  }
}

export default function () {
  return async (req, res, next) => {
    if (!req.url.startsWith('/api/auth')) return next()
    const send = (code, obj) => {
      res.statusCode = code
      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify(obj))
    }
    const path = req.url.replace('/api/auth', '') || '/'
    const M = req.$m

    // GET /api/auth/me
    if (req.method === 'GET' && path === '/me') {
      if (!req.$auth.user) return send(200, { user: null })
      try {
        const u = await M.users.get(req.$auth.user.id)
        if (!u || u.active === 0) {
          req.$auth.clearUserCookie?.()
          return send(200, { user: null })
        }
        return send(200, { user: u })
      } catch {
        return send(200, { user: null })
      }
    }

    // POST /api/auth/signout
    if (req.method === 'POST' && path === '/signout') {
      req.$auth.clearUserCookie?.()
      return send(200, { ok: true })
    }

    // POST /api/auth/signup { email,password }
    if (req.method === 'POST' && path === '/signup') {
      const { email, password } = req.body || {}
      if (!email || !password || String(password).length < 8) return send(400, { error: 'invalid' })
      try {
        const hash = await argon2.hash(password, { type: argon2.argon2id })
        const user = await M.users.create(email.toLowerCase(), hash)
        req.$auth.setUserCookie?.(user)
        await sendVerifyMail(req, user)
        return send(201, { user })
      } catch (e) {
        const msg = String(e || '')
        return send(msg.includes('UNIQUE') || msg.includes('exists') ? 409 : 500, {
          error: msg.includes('UNIQUE') ? 'email_taken' : 'server',
        })
      }
    }

    // POST /api/auth/signin { email,password }
    if (req.method === 'POST' && path === '/signin') {
      const { email, password } = req.body || {}
      if (!email || !password) return send(400, { error: 'invalid' })
      const u = await M.users.byEmail(email.toLowerCase()).catch(() => null)
      if (!u || u.active === 0 || !u.password_hash) return send(401, { error: 'invalid_creds' })
      const ok = await argon2.verify(u.password_hash, password)
      if (!ok) return send(401, { error: 'invalid_creds' })
      const user = {
        id: u.id,
        email: u.email,
        role: u.role,
        active: u.active,
        email_verified: u.email_verified,
        email_verified_at: u.email_verified_at,
      }
      req.$auth.setUserCookie?.(user)
      return send(200, { user })
    }

    // POST /api/auth/request-verify
    if (req.method === 'POST' && path === '/request-verify') {
      if (!req.$auth.user) return send(401, { error: 'auth' })
      const u = await M.users.get(req.$auth.user.id).catch(() => null)
      if (!u) return send(404, { error: 'not_found' })
      if (u.email_verified) return send(200, { ok: true, already: true })
      await sendVerifyMail(req, u)
      return send(200, { ok: true })
    }

    // GET /api/auth/verify?token=...
    if (req.method === 'GET' && path.startsWith('/verify')) {
      const token = new URL('http://x' + path).searchParams.get('token')
      if (!token) return send(400, { error: 'invalid' })
      const data = verifyToken(token)
      if (!data || data.typ !== 'verify') return send(400, { error: 'invalid' })
      const u = await M.users.get(data.uid).catch(() => null)
      if (!u || u.email.toLowerCase() !== data.email.toLowerCase())
        return send(400, { error: 'invalid' })
      if (!u.email_verified) {
        await M.users.update(u.id, {
          email_verified: 1,
          email_verified_at: new Date().toISOString(),
        })
      }
      return send(200, { ok: true })
    }

    // POST /api/auth/forgot { email }
    if (req.method === 'POST' && path === '/forgot') {
      const { email } = req.body || {}
      if (!email) return send(400, { error: 'invalid' })
      const u = await M.users.byEmail(email.toLowerCase()).catch(() => null)
      if (!u || u.active === 0) return send(200, { ok: true }) // silent
      const jti = nanoid()
      const token = sign({ typ: 'reset', uid: u.id, email: u.email }, RESET_TTL, { jti })
      await M.resets.create(jti, u.id, new Date(Date.now() + RESET_TTL * 1000).toISOString())
      await sendResetMail(req, u, token)
      return send(200, { ok: true })
    }

    // POST /api/auth/reset { token,password }
    if (req.method === 'POST' && path === '/reset') {
      const { token, password } = req.body || {}
      if (!token || !password || String(password).length < 8) return send(400, { error: 'invalid' })
      const data = verifyToken(token)
      if (!data || data.typ !== 'reset') return send(400, { error: 'invalid' })
      const u = await M.users.get(data.uid).catch(() => null)
      if (!u || u.email.toLowerCase() !== data.email.toLowerCase())
        return send(400, { error: 'invalid' })
      const rec = await M.resets.get(data.jti, u.id).catch(() => null)
      if (!rec || rec.used) return send(400, { error: 'invalid' })
      if (new Date(rec.expires_at).getTime() < Date.now()) return send(400, { error: 'expired' })
      const hash = await argon2.hash(password, { type: argon2.argon2id })
      await M.users.update(u.id, { password_hash: hash, updated_at: new Date().toISOString() })
      await M.resets.markUsed(rec.id)
      return send(200, { ok: true })
    }

    return send(404, { error: 'not_found' })
  }
}

// Email helpers (same as before)
async function sendVerifyMail(req, user) {
  const SECRET = process.env.JWT_SECRET || 'dev-secret-change-me'
  const token = jwt.sign({ typ: 'verify', uid: user.id, email: user.email }, SECRET, {
    expiresIn: 60 * 60 * 24,
  })
  const url = `${req.$mailer.origin}/auth/verify?token=${encodeURIComponent(token)}`
  const html = `<p>Verify your <strong>MUMPS.IO</strong> email:</p><p><a href="${url}">${url}</a></p><p>Expires in 24h.</p>`
  await req.$mailer.send({ to: user.email, subject: 'Verify your email', html })
}
async function sendResetMail(req, user, token) {
  const url = `${req.$mailer.origin}/auth/reset?token=${encodeURIComponent(token)}`
  const html = `<p>Password reset for <strong>MUMPS.IO</strong>:</p><p><a href="${url}">${url}</a></p>`
  await req.$mailer.send({ to: user.email, subject: 'Reset your password', html })
}
