<template>
  <div class="auth-wrap">
    <div class="auth-card surface" ref="card">
      <h1 class="title">Forgot password</h1>
      <p class="sub">Enter your email and we’ll send you a reset link.</p>
      <form @submit.prevent="submit">
        <div class="field">
          <label>Email</label>
          <input type="email" v-model.trim="email" required />
        </div>
        <div class="actions">
          <button class="btn btn-primary" :disabled="busy">
            {{ busy ? 'Sending…' : 'Send link' }}
          </button>
          <button class="btn" type="button" @click="$router.push({ name: 'signin' })">
            Back to sign in
          </button>
        </div>
        <p class="sub" v-if="sent">If that email exists, we’ve sent a link.</p>
      </form>
    </div>
  </div>
</template>

<script>
import gsap from 'gsap'
import { authApi } from '../../api/auth'
export default {
  name: 'ForgotPassword',
  data() {
    return { email: '', busy: false, sent: false }
  },
  mounted() {
    gsap.from(this.$refs.card, { y: 8, opacity: 0, duration: 0.45, ease: 'power2.out' })
  },
  methods: {
    async submit() {
      this.busy = true
      try {
        await authApi.forgot(this.email)
      } finally {
        this.busy = false
        this.sent = true
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
.field {
  display: grid;
  gap: 6px;
  margin-bottom: 10px;
}
.field label {
  font-weight: 700;
  font-size: 12px;
  color: var(--text-dim);
}
.field input {
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.actions {
  display: flex;
  gap: 10px;
}
</style>
