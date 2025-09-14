import { reactive } from 'vue'
import { authApi } from '../api/auth'

export const authState = reactive({
  user: null, // { id,email,role,active,email_verified,email_verified_at }
  loaded: false,
})

export async function bootstrapAuth() {
  try {
    const { user } = await authApi.me()
    authState.user = user
  } catch {
    authState.user = null
  } finally {
    authState.loaded = true
  }
}
