function qs(obj) {
  const p = new URLSearchParams(obj)
  return `?${p.toString()}`
}
export const adminApi = {
  users: (params) => fetch('/api/admin/users' + qs(params || {})).then((r) => r.json()),
  setRole: (id, role) =>
    fetch(`/api/admin/users/${id}/role`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-csrf-token': document.cookie.match(/(?:^|;\s*)csrf=([^;]+)/)?.[1] || '',
      },
      body: JSON.stringify({ role }),
    }).then((r) => r.json()),
  setStat: (id, active) =>
    fetch(`/api/admin/users/${id}/status`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-csrf-token': document.cookie.match(/(?:^|;\s*)csrf=([^;]+)/)?.[1] || '',
      },
      body: JSON.stringify({ active }),
    }).then((r) => r.json()),
  stats: () => fetch('/api/admin/stats').then((r) => r.json()),
}
