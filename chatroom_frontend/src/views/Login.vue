<template>
  <div class="login-container">
    <!-- Animated background shapes (warm tones, not centered) -->
    <div class="bg-blob bg-blob--1"></div>
    <div class="bg-blob bg-blob--2"></div>
    <div class="bg-blob bg-blob--3"></div>

    <div class="login-card">
      <!-- Header -->
      <div class="login-header">
        <div class="login-brand">
          <BrandMark class="login-logo" :size="52" />
          <div class="login-brand-copy">
            <span class="login-kicker">Team console</span>
            <h2 class="app-title">ConnectHub</h2>
          </div>
        </div>
        <div class="title-divider"></div>
        <p class="login-subtitle">Welcome back. Let's go.</p>
      </div>

      <!-- Form -->
      <form @submit.prevent="login" class="login-form">
        <div class="input-group">
          <span class="input-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
          </span>
          <input
            v-model="username"
            placeholder="Username"
            aria-label="Username"
            autocomplete="username"
            required
            autofocus
          />
        </div>

        <div class="input-group">
          <span class="input-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </span>
          <input
            v-model="password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="Password"
            aria-label="Password"
            autocomplete="current-password"
            required
          />
          <button type="button" class="toggle-pw" @click="showPassword = !showPassword" tabindex="-1" :aria-label="showPassword ? 'Hide password' : 'Show password'">
            <svg v-if="!showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
              <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
              <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
              <line x1="1" y1="1" x2="23" y2="23"/>
            </svg>
          </button>
        </div>

        <!-- Inline error -->
        <transition name="shake">
          <div v-if="errorMsg" class="error-msg">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            {{ errorMsg }}
          </div>
        </transition>

        <button type="submit" class="btn-login" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          <span v-else>Sign in</span>
        </button>
      </form>

      <div class="login-footer">
        <small>&copy; {{ new Date().getFullYear() }} ConnectHub</small>
      </div>
    </div>
  </div>
</template>

<script>
import BrandMark from '../components/BrandMark.vue'

export default {
  name: 'LoginPage',
  components: { BrandMark },
  data() {
    return {
      username: '',
      password: '',
      showPassword: false,
      loading: false,
      errorMsg: ''
    }
  },
  mounted() {
    const msg = sessionStorage.getItem('logout_message')
    if (msg) {
      this.errorMsg = msg
      sessionStorage.removeItem('logout_message')
    }
  },
  methods: {
    async login() {
      this.errorMsg = ''
      this.loading = true
      try {
        const { login } = await import('../services/auth.service.js')
        const res = await login(this.username, this.password)
        this.$store.dispatch('auth/login', { user: res.data })
        const role = res.data?.role
        this.$router.push(role === 'SUPER_ADMIN' ? '/admin' : '/home')
      } catch (error) {
        if (error.response) {
          if (error.response.status === 403) {
            this.errorMsg = 'Account disabled by admin'
          } else if (error.response.status === 401) {
            this.errorMsg = 'Wrong username or password'
          } else {
            this.errorMsg = 'Error: ' + (error.response.data?.message || error.message)
          }
        } else {
          this.errorMsg = 'Connection lost: ' + error.message
        }
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
/* Container – asymmetric placement, warm gradient bg */
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding: 24px 24px 24px 12%;
  background:
    linear-gradient(145deg, #faf8f5 0%, #f5f0ea 40%, #ede5db 100%);
  /* noise overlay */
  background-image:
    url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='.04'/%3E%3C/svg%3E"),
    linear-gradient(145deg, #faf8f5 0%, #f5f0ea 40%, #ede5db 100%);
  position: relative;
  overflow: hidden;
}

.login-container::before,
.login-container::after {
  content: '';
  position: absolute;
  inset: -18%;
  pointer-events: none;
}

.login-container::before {
  background:
    radial-gradient(ellipse at 18% 24%, rgba(15, 118, 110, 0.16), transparent 32%),
    radial-gradient(ellipse at 74% 18%, rgba(217, 119, 6, 0.14), transparent 30%),
    radial-gradient(ellipse at 82% 78%, rgba(234, 88, 12, 0.12), transparent 34%);
  filter: blur(18px);
  opacity: 0.82;
  animation: loginAurora 18s cubic-bezier(0.22, 0.61, 0.36, 1) infinite alternate;
}

.login-container::after {
  background-image:
    url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='240' height='240'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.82' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='.035'/%3E%3C/svg%3E");
  mix-blend-mode: multiply;
  opacity: 0.58;
  animation: grainDrift 9s steps(6) infinite;
}

.bg-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.22;
  pointer-events: none;
  animation: blobFloat 8s cubic-bezier(0.22, 0.61, 0.36, 1) infinite alternate;
}
.bg-blob--1 {
  width: 440px; height: 440px;
  background: #0f766e;
  top: -140px; left: -80px;
  animation-duration: 11s;
}
.bg-blob--2 {
  width: 360px; height: 360px;
  background: #d97706;
  bottom: -90px; right: -40px;
  animation-duration: 13s;
  animation-delay: -3s;
}
.bg-blob--3 {
  width: 240px; height: 240px;
  background: #ea580c;
  top: 55%; left: 65%;
  animation-duration: 9s;
  animation-delay: -5s;
}

@keyframes blobFloat {
  0%   { transform: translate(0, 0) scale(1) rotate(0deg); }
  100% { transform: translate(42px, -30px) scale(1.12) rotate(10deg); }
}

@keyframes loginAurora {
  0% { transform: translate3d(-2%, 1%, 0) rotate(-2deg) scale(1); }
  45% { transform: translate3d(3%, -2%, 0) rotate(2deg) scale(1.04); }
  100% { transform: translate3d(5%, 3%, 0) rotate(-1deg) scale(1.08); }
}

@keyframes grainDrift {
  0% { transform: translate3d(0, 0, 0); }
  100% { transform: translate3d(24px, -18px, 0); }
}

/* Card */
.login-card {
  width: 100%;
  max-width: 400px;
  background: #fefdfb;
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border: 1px solid #e0d8cf;
  border-radius: 22px;
  box-shadow: 0 20px 60px rgba(28, 18, 10, 0.08), 0 4px 16px rgba(28, 18, 10, 0.04);
  overflow: hidden;
  animation: cardIn 500ms cubic-bezier(0.22, 0.61, 0.36, 1);
  position: relative;
  z-index: 1;
}

@keyframes cardIn {
  from { opacity: 0; transform: translateY(24px) scale(0.96); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

/* Header */
.login-header {
  text-align: left;
  padding: 40px 32px 24px;
}

.login-brand {
  display: flex;
  align-items: center;
  gap: 14px;
}

.login-logo {
  flex: 0 0 auto;
  filter: drop-shadow(0 12px 22px rgba(15, 118, 110, 0.16));
}

.login-brand-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.login-kicker {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #9a6b48;
}

.app-title {
  margin: 0;
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: -0.5px;
  background: linear-gradient(135deg, #0f766e, #d97706);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.title-divider {
  width: 52px;
  height: 3px;
  margin: 14px 0;
  border-radius: 2px;
  background: linear-gradient(90deg, #0f766e, #d97706);
  opacity: 0.75;
}

.login-subtitle {
  margin: 0;
  color: #57534e;
  font-size: 0.95rem;
  font-weight: 500;
  letter-spacing: 0.2px;
}

/* Form */
.login-form {
  padding: 8px 32px 24px;
}

.input-group {
  position: relative;
  margin-bottom: 16px;
  width: 100%;
  height: 64px;
  border-radius: 18px;
  border: 1px solid #e0d8cf;
  background: #faf8f5;
  overflow: hidden;
  transition: border-color 0.25s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.25s cubic-bezier(0.22, 0.61, 0.36, 1), background 0.25s;
}

.input-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #a8a29e;
  display: flex;
  pointer-events: none;
  transition: color 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.input-group input {
  display: block;
  width: 100%;
  height: 100%;
  padding: 0 48px 0 54px;
  border: 0;
  background: transparent;
  color: #1c1917;
  font-size: 0.95rem;
  box-sizing: border-box;
}
.input-group input::placeholder {
  color: #a8a29e;
}
.input-group input:focus {
  outline: none;
}
.input-group:focus-within {
  border-color: #0f766e;
  background: #fefdfb;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.12);
}
.input-group:focus-within .input-icon {
  color: #0f766e;
}

.toggle-pw {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: #a8a29e;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 12px;
  padding: 0;
  transition: color 0.2s;
}
.toggle-pw:hover {
  color: #57534e;
}

/* Error */
.error-msg {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  padding: 10px 14px;
  border-radius: 11px;
  font-size: 0.85rem;
  margin-bottom: 14px;
}

.shake-enter-active {
  animation: shake 0.4s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%      { transform: translateX(-6px); }
  40%      { transform: translateX(6px); }
  60%      { transform: translateX(-4px); }
  80%      { transform: translateX(4px); }
}

/* Button */
.btn-login {
  width: 100%;
  margin-top: 4px;
  padding: 13px;
  background: linear-gradient(135deg, #0f766e, #d97706);
  color: #fff;
  border: none;
  border-radius: 13px;
  cursor: pointer;
  font-weight: 700;
  font-size: 1rem;
  letter-spacing: 0.3px;
  transition: transform 0.12s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.25s cubic-bezier(0.22, 0.61, 0.36, 1), opacity 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
}
.btn-login:hover:not(:disabled) {
  box-shadow: 0 8px 24px rgba(15, 118, 110, 0.3);
  transform: translateY(-1px);
}
.btn-login:active:not(:disabled) {
  transform: translateY(1px);
}
.btn-login:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.spinner {
  width: 22px; height: 22px;
  border: 2.5px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.65s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Footer */
.login-footer {
  text-align: left;
  padding: 14px 32px 20px;
  color: #a8a29e;
  font-size: 0.78rem;
}

/* Mobile */
@media (max-width: 640px) {
  .login-container {
    justify-content: center;
    padding: 24px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .login-container::before,
  .login-container::after,
  .bg-blob,
  .login-card,
  .spinner {
    animation: none;
  }
}
</style>
