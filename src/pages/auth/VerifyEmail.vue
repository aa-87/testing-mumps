<template>
  <div class="auth-wrap">
    <div class="auth-card surface" ref="card">
      <h1 class="title">Verify email</h1>
      <p class="sub" v-if="status === 'idle'">Verifying your email…</p>
      <p class="sub ok" v-if="status === 'ok'">
        Your email has been verified. You can close this tab.
      </p>
      <p class="sub err" v-if="status === 'err'">Verification link is invalid or expired.</p>

      <div class="actions">
        <button class="btn btn-primary" @click="$router.push({ name: 'practice-index' })">
          Go to Practice
        </button>
        <button class="btn" v-if="!verified" :disabled="busy" @click="resend">
          {{ busy ? 'Sending…' : 'Resend link' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import gsap from 'gsap'
import { authApi } from '../../api/auth'
import { authState, bootstrapAuth } from '../../stores/authState'

export default {
  name: 'VerifyEmail',
  data() {
    return { status: 'idle', busy: false }
  },
  computed: {
    verified() {
      return !!authState.user?.email_verified
    },
  },
  async mounted() {
    gsap.from(this.$refs.card, { y: 8, opacity: 0, duration: 0.45, ease: 'power2.out' })
    const token = this.$route.query.token
    if (!token) {
      this.status = 'err'
      return
    }
    const res = await authApi.verify(token).catch(() => ({ ok: false }))
    this.status = res?.ok ? 'ok' : 'err'
    await bootstrapAuth()
  },
  methods: {
    async resend() {
      this.busy = true
      try {
        await authApi.requestVerify()
      } finally {
        this.busy = false
      }
    },
  },
}
</script>

<style scoped>
.auth-wrap {
  min-height: 100svh;
  display: grid;
  place-items: center;
  padding: 24px 16px;
}
.auth-card {
  width: min(520px, 92vw);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 18px;
}
.title {
  margin: 0 0 6px;
  font-size: 20px;
}
.sub {
  margin: 0 0 12px;
  color: var(--text-dim);
}
.sub.ok {
  color: #22c55e;
}
.sub.err {
  color: #ef4444;
}
.actions {
  display: flex;
  gap: 10px;
}
</style>
