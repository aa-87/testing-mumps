// Switch to real WS by setting USE_MOCK=false and updating WS_URL
const USE_MOCK = true
const WS_URL = 'wss://your-mumps-ws.example/ws/problems' // when ready

export function connectProblemSession(problemId) {
  if (!USE_MOCK) return new WebSocket(`${WS_URL}?pid=${encodeURIComponent(problemId)}`)
  return createMockSocket({ problemId })
}

/* ---------------- MOCK ---------------- */
function delay(ms) {
  return new Promise((r) => setTimeout(r, ms))
}
function createMockSocket({ problemId }) {
  console.log(problemId)
  const listeners = { open: [], message: [], close: [], error: [] }
  const sock = {
    readyState: 0,
    addEventListener(t, fn) {
      listeners[t]?.push(fn)
    },
    removeEventListener(t, fn) {
      const a = listeners[t] || []
      const i = a.indexOf(fn)
      if (i >= 0) a.splice(i, 1)
    },
    send(data) {
      try {
        const m = JSON.parse(data)
        if (m.op === 'run') flowRun()
        else if (m.op === 'submit') flowSubmit()
      } catch (e) {
        console.log(e)
      }
    },
    close() {
      listeners.close.forEach((fn) => fn({ code: 1000 }))
    },
  }
  setTimeout(() => {
    sock.readyState = 1
    listeners.open.forEach((fn) => fn({}))
  }, 60)

  async function flowRun() {
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'compile:start' }) }))
    await delay(160)
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'compile:ok', time: 26 }) }),
    )
    await delay(120)
    for (let i = 1; i <= 3; i++) {
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
      await delay(120)
    }
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'done', verdict: 'Accepted', runtime: 15, memory: 1.6 }) }),
    )
  }
  async function flowSubmit() {
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'queue', position: 2 }) }))
    await delay(220)
    listeners.message.forEach((fn) => fn({ data: JSON.stringify({ type: 'compile:start' }) }))
    await delay(200)
    listeners.message.forEach((fn) =>
      fn({ data: JSON.stringify({ type: 'compile:ok', time: 31 }) }),
    )
    await delay(140)
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
