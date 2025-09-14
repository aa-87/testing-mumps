function csrf() {
  const m = document.cookie.match(/(?:^|;\s*)csrf=([^;]+)/)
  return m ? decodeURIComponent(m[1]) : ''
}
async function _post(path, body) {
  const res = await fetch(`/api/auth${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-csrf-token': csrf(),
      Accept: 'application/json',
    },
    body: JSON.stringify(body || {}),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw Object.assign(new Error('Auth error'), { status: res.status, data })
  return data
}

async function _get(path) {
  const res = await fetch(`/api/auth${path}`, { headers: { Accept: 'application/json' } })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw Object.assign(new Error('Auth error'), { status: res.status, data })
  return data
}

export const authApi = {
  me: () => _get('/me'),
  signup: (email, password) => _post('/signup', { email, password }),
  signin: (email, password) => _post('/signin', { email, password }),
  signout: () => _post('/signout', {}),
  requestVerify: () => _post('/request-verify', {}),
  verify: (token) =>
    fetch(`/api/auth/verify?token=${encodeURIComponent(token)}`).then((r) => r.json()),
  forgot: (email) => _post('/forgot', { email }),
  reset: (token, password) => _post('/reset', { token, password }),
}
