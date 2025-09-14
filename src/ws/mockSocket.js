function delayed(ms) {
  return new Promise((r) => setTimeout(r, ms))
}

export function createMockSocket({ problemId }) {
  console.log(problemId)
  const listeners = { open: [], message: [], close: [], error: [] }
  let closed = false

  const sock = {
    readyState: 0, // 0=CONNECTING, 1=OPEN, 2=CLOSING, 3=CLOSED
    addEventListener(type, fn) {
      listeners[type]?.push(fn)
    },
    removeEventListener(type, fn) {
      const a = listeners[type]
      if (!a) return
      const i = a.indexOf(fn)
      if (i >= 0) a.splice(i, 1)
    },
    send(data) {
      // Expect JSON: { op: 'run'|'submit', code: '...', input?: '...' }
      try {
        const msg = JSON.parse(data || '{}')
        if (msg.op === 'run') runFlow()
        else if (msg.op === 'submit') submitFlow()
      } catch (e) {
        console.log(e)
      }
    },
    close() {
      closed = true
      sock.readyState = 3
      listeners.close.forEach((fn) => fn({ code: 1000, reason: 'mock closed' }))
    },
  }

  // open asynchronously
  setTimeout(() => {
    if (closed) return
    sock.readyState = 1
    listeners.open.forEach((fn) => fn({}))
  }, 80)

  async function runFlow() {
    if (closed) return
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'compile:start' }) }))
    await delayed(180)
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'compile:ok', time: 22 }) }),
    )
    await delayed(120)
    for (let i = 1; i <= 3; i++) {
      if (closed) return
      listeners.message.forEach((fn) =>
        fn({
          data: JSON.stringify({
            type: 'run:case',
            case: i,
            total: 3,
            status: 'OK',
            time: 4 + i,
            memory: 1.2 + i * 0.1,
          }),
        }),
      )
      await delayed(120)
    }
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'done', verdict: 'Accepted', runtime: 15, memory: 1.6 }) }),
    )
  }

  async function submitFlow() {
    if (closed) return
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'queue', position: 3 }) }))
    await delayed(250)
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'queue', position: 1 }) }))
    await delayed(250)
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'compile:start' }) }))
    await delayed(250)
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'compile:ok', time: 28 }) }),
    )
    await delayed(140)
    listeners.message.forEach((fn) =>
      fn({
        data: JSON.stringify({
          type: 'done',
          verdict: 'Accepted',
          runtime: 18,
          memory: 1.9,
          percentile: 84,
        }),
      }),
    )
  }

  return sock
}
