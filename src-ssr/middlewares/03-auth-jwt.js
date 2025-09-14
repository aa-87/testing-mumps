import jwt from 'jsonwebtoken'

const ACCESS_COOKIE = 'sid' // HttpOnly
// const CSRF_COOKIE = 'csrf' // readable (double-submit)
const ACCESS_TTL = 60 * 60 * 4 // 4h
const SECRET = process.env.JWT_SECRET || 'dev-secret-change-me'

function signAccess(payload) {
  return jwt.sign(payload, SECRET, { expiresIn: ACCESS_TTL })
}
function verifyAccess(token) {
  try {
    return jwt.verify(token, SECRET)
  } catch {
    return null
  }
}

// Attach helpers to req/res and parse current user (if present)
export default function () {
  return (req, res, next) => {
    req.$auth = {
      user: null,
      setUserCookie(user) {
        const token = signAccess({ id: user.id, email: user.email })
        const secure = process.env.NODE_ENV === 'production'
        res.cookie(ACCESS_COOKIE, token, {
          httpOnly: true,
          sameSite: 'lax',
          secure,
          path: '/',
          maxAge: ACCESS_TTL * 1000,
        })
      },
      clearUserCookie() {
        const secure = process.env.NODE_ENV === 'production'
        res.cookie(ACCESS_COOKIE, '', {
          httpOnly: true,
          sameSite: 'lax',
          secure,
          path: '/',
          maxAge: 0,
        })
      },
    }
    const token = req.cookies?.[ACCESS_COOKIE]
    if (token) {
      const data = verifyAccess(token)
      if (data) req.$auth.user = { id: data.id, email: data.email }
    }
    next()
  }
}
