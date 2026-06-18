<template>
  <div class="login-container">
    <!-- Animated background blobs -->
    <div class="bg-blob bg-blob--1"></div>
    <div class="bg-blob bg-blob--2"></div>
    <div class="bg-blob bg-blob--3"></div>

    <div class="login-card">
      <!-- Header -->
      <div class="login-header">
        <h2 class="app-title">ConnectHub</h2>
        <div class="title-divider"></div>
        <p class="login-subtitle">Inicia sesión para continuar</p>
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
            placeholder="Usuario"
            aria-label="Usuario"
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
            placeholder="Contraseña"
            aria-label="Contraseña"
            autocomplete="current-password"
            required
          />
          <button type="button" class="toggle-pw" @click="showPassword = !showPassword" tabindex="-1" :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'">
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
          <span v-else>Entrar</span>
        </button>
      </form>

      <div class="login-footer">
        <small>© {{ new Date().getFullYear() }} ConnectHub</small>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LoginPage',
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
            this.errorMsg = 'Tu cuenta ha sido deshabilitada por un Super Admin'
          } else if (error.response.status === 401) {
            this.errorMsg = 'Usuario o contraseña incorrectos'
          } else {
            this.errorMsg = 'Error: ' + (error.response.data?.message || error.message)
          }
        } else {
          this.errorMsg = 'Error de conexión: ' + error.message
        }
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
/* ── Container & animated blobs ── */
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
  padding: 24px;
  position: relative;
  overflow: hidden;
}

.bg-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.45;
  pointer-events: none;
  animation: blobFloat 8s ease-in-out infinite alternate;
}
.bg-blob--1 {
  width: 420px; height: 420px;
  background: var(--brand-gradient-start);
  top: -120px; left: -100px;
  animation-duration: 10s;
}
.bg-blob--2 {
  width: 350px; height: 350px;
  background: var(--brand-gradient-end);
  bottom: -80px; right: -60px;
  animation-duration: 12s;
  animation-delay: -3s;
}
.bg-blob--3 {
  width: 260px; height: 260px;
  background: #8b5cf6;
  top: 50%; left: 60%;
  animation-duration: 9s;
  animation-delay: -5s;
}

@keyframes blobFloat {
  0%   { transform: translate(0, 0) scale(1); }
  100% { transform: translate(40px, -30px) scale(1.12); }
}

/* ── Card ── */
.login-card {
  width: 100%;
  max-width: 400px;
  background: rgba(255, 255, 255, 0.07);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.35);
  overflow: hidden;
  animation: cardIn 500ms cubic-bezier(0.22, 1, 0.36, 1);
  position: relative;
  z-index: 1;
}

@keyframes cardIn {
  from { opacity: 0; transform: translateY(24px) scale(0.96); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

/* ── Header ── */
.login-header {
  text-align: center;
  padding: 40px 28px 24px;
}

.app-title {
  margin: 0;
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: -0.5px;
  background: linear-gradient(135deg, #818cf8, #38bdf8, #a78bfa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.title-divider {
  width: 48px;
  height: 3px;
  margin: 14px auto;
  border-radius: 2px;
  background: linear-gradient(90deg, var(--brand-gradient-start), var(--brand-gradient-end));
  opacity: 0.7;
}

.login-subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.9rem;
  font-weight: 400;
  letter-spacing: 0.2px;
}

/* ── Form ── */
.login-form {
  padding: 8px 28px 24px;
}

.input-group {
  position: relative;
  margin-bottom: 16px;
}

.input-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(255, 255, 255, 0.4);
  display: flex;
  pointer-events: none;
  transition: color 0.2s;
}

.input-group input {
  display: block;
  width: 100%;
  padding: 13px 44px 13px 44px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.06);
  color: #fff;
  font-size: 0.95rem;
  transition: border-color 0.25s, box-shadow 0.25s, background 0.25s;
  box-sizing: border-box;
}
.input-group input::placeholder {
  color: rgba(255, 255, 255, 0.35);
}
.input-group input:focus {
  outline: none;
  border-color: var(--brand-gradient-start);
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.3);
}
.input-group:focus-within .input-icon {
  color: var(--brand-gradient-start);
}

.toggle-pw {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.35);
  cursor: pointer;
  display: flex;
  padding: 2px;
  transition: color 0.2s;
}
.toggle-pw:hover {
  color: rgba(255, 255, 255, 0.7);
}

/* ── Error ── */
.error-msg {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(220, 38, 38, 0.15);
  border: 1px solid rgba(220, 38, 38, 0.3);
  color: #fca5a5;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 0.85rem;
  margin-bottom: 14px;
}

.shake-enter-active {
  animation: shake 0.4s ease;
}
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%      { transform: translateX(-6px); }
  40%      { transform: translateX(6px); }
  60%      { transform: translateX(-4px); }
  80%      { transform: translateX(4px); }
}

/* ── Button ── */
.btn-login {
  width: 100%;
  margin-top: 4px;
  padding: 13px;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  color: #fff;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  font-size: 1rem;
  letter-spacing: 0.3px;
  transition: transform 0.12s ease, box-shadow 0.25s ease, opacity 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
}
.btn-login:hover:not(:disabled) {
  box-shadow: 0 8px 24px rgba(79, 70, 229, 0.45);
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

/* ── Footer ── */
.login-footer {
  text-align: center;
  padding: 14px 28px 20px;
  color: rgba(255, 255, 255, 0.3);
  font-size: 0.78rem;
}
</style>
