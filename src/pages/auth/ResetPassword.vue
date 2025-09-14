<template>
  <div class="auth-wrap">
    <div class="auth-card surface" ref="card">
      <h1 class="title">Reset password</h1>
      <p class="sub" v-if="!token">Invalid reset link.</p>
      <form v-else @submit.prevent="submit">
        <div class="field">
          <label>New password</label>
          <input :type="show ? 'text' : 'password'" v-model="password" required />
          <button type="button" class="tiny" @click="show = !show">
            {{ show ? 'Hide' : 'Show' }}
          </button>
        </div>
        <div class="field">
          <label>Confirm</label>
          <input :type="show ? 'text' : 'password'" v-model="confirm" required />
        </div>
        <div class="actions">
          <button class="btn btn-primary" :disabled="busy || !valid">
            {{ busy ? 'Saving…' : 'Set password' }}
          </button>
          <button class="btn" type="button" @click="$router.push({ name: 'signin' })">
            Back to sign in
          </button>
        </div>
        <div class="form-err" v-if="err">{{ err }}</div>
        <div class="sub ok" v-if="done">Password updated. You may sign in now.</div>
      </form>
    </div>
  </div>
</template>

<script>
import gsap from 'gsap'
import { authApi } from '../../api/auth'
export default {
  name: 'ResetPassword',
  data() {
    return {
      token: this.$route.query.token || '',
      password: '',
      confirm: '',
      show: false,
      busy: false,
      err: '',
      done: false,
    }
  },
  mounted() {
    gsap.from(this.$refs.card, { y: 8, opacity: 0, duration: 0.45, ease: 'power2.out' })
  },
  computed: {
    valid() {
      return this.password && this.password.length >= 8 && this.password === this.confirm
    },
  },
  methods: {
    async submit() {
      if (!this.valid) {
        this.err = 'Password too short or mismatch'
        return
      }
      this.err = ''
      this.busy = true
      try {
        await authApi.reset(this.token, this.password)
        this.done = true
      } catch (e) {
        this.err = e?.data?.error === 'expired' ? 'Link expired' : 'Reset failed'
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
.field {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
  margin-bottom: 10px;
}
.field label {
  grid-column: 1/-1;
  font-weight: 700;
  font-size: 12px;
  color: var(--text-dim);
}
.field input {
  grid-column: 1/2;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.tiny {
  grid-column: 2/3;
  padding: 6px 8px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-dim);
  font-size: 12px;
}
.actions {
  display: flex;
  gap: 10px;
  margin-top: 6px;
}
.form-err {
  margin-top: 8px;
  color: #ef4444;
  font-weight: 600;
}
</style>
