<template>
  <div class="auth-wrap">
    <div class="auth-card surface" ref="card">
      <div class="brand gradient-text">MUMPS.IO</div>
      <h1 class="title">Create your account</h1>
      <p class="sub">Start practicing M right away.</p>

      <form @submit.prevent="submit">
        <div class="field">
          <label>Email</label>
          <input type="email" v-model.trim="email" autocomplete="email" required />
          <div class="err" v-if="errors.email">{{ errors.email }}</div>
        </div>

        <div class="field">
          <label>Password</label>
          <input
            :type="show ? 'text' : 'password'"
            v-model="password"
            autocomplete="new-password"
            required
          />
          <button type="button" class="tiny" @click="show = !show">
            {{ show ? 'Hide' : 'Show' }}
          </button>
          <div class="err" v-if="errors.password">{{ errors.password }}</div>
        </div>

        <div class="field">
          <label>Confirm password</label>
          <input
            :type="show ? 'text' : 'password'"
            v-model="confirm"
            autocomplete="new-password"
            required
          />
          <div class="err" v-if="errors.confirm">{{ errors.confirm }}</div>
        </div>

        <div class="actions">
          <button class="btn btn-primary" :disabled="busy">
            {{ busy ? 'Creating…' : 'Sign up' }}
          </button>
          <button class="btn" type="button" @click="$router.push({ name: 'signin' })">
            Sign in
          </button>
        </div>

        <div class="form-err" v-if="formError">{{ formError }}</div>
      </form>
    </div>
  </div>
</template>

<script>
import gsap from 'gsap'
import { authApi } from '../../api/auth'
import { authState } from '../../stores/authState'

export default {
  name: 'SignUp',
  data() {
    return {
      email: '',
      password: '',
      confirm: '',
      show: false,
      busy: false,
      errors: {},
      formError: '',
    }
  },
  mounted() {
    gsap.from(this.$refs.card, { y: 8, opacity: 0, duration: 0.45, ease: 'power2.out' })
  },
  methods: {
    validate() {
      const e = {}
      if (!this.email) e.email = 'Email is required'
      if (!this.password) e.password = 'Password is required'
      else if (this.password.length < 8) e.password = 'At least 8 characters'
      if (this.confirm !== this.password) e.confirm = 'Passwords do not match'
      this.errors = e
      return Object.keys(e).length === 0
    },
    async submit() {
      if (!this.validate()) return
      this.busy = true
      this.formError = ''
      try {
        const { user } = await authApi.signup(this.email, this.password)
        authState.user = user
        this.$router.replace({ name: 'practice-index' })
      } catch (err) {
        //const code = err?.status
        const data = err?.data || {}
        this.formError =
          data.error === 'email_taken'
            ? 'Email already registered'
            : data.error === 'rate_limit'
              ? 'Too many attempts. Try again later.'
              : 'Sign up failed'
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
.brand {
  font-weight: 900;
  letter-spacing: 0.02em;
  font-size: 18px;
}
.title {
  margin: 6px 0;
  font-size: 20px;
}
.sub {
  margin: 0 0 12px;
  color: var(--text-dim);
  font-size: 13px;
}
.field {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}
.field label {
  grid-column: 1 / -1;
  font-weight: 700;
  font-size: 12px;
  color: var(--text-dim);
}
.field input {
  grid-column: 1 / 2;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 94%, transparent);
  color: var(--text);
}
.field .tiny {
  grid-column: 2 / 3;
  justify-self: end;
  padding: 6px 8px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-dim);
  font-size: 12px;
}
.err {
  grid-column: 1 / -1;
  color: #ef4444;
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
