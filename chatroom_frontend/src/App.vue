<template>
  <router-view v-slot="{ Component }">
    <transition name="view-fade" mode="out-in">
      <component :is="Component" />
    </transition>
  </router-view>
</template>

<script>
import { setControlCallback } from './services/websocket'
import { checkStatus } from './services/auth.service'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'App',
  created() {
    setControlCallback(this.handleControlMessage)
    
    if (this.isAuthenticated && this.currentUser?.username) {
      this.verifyAccountStatus()
    }

    this.statusInterval = setInterval(() => {
      if (this.isAuthenticated && this.currentUser?.username) {
        this.verifyAccountStatus()
      }
    }, 30000)
  },
  beforeUnmount() {
    if (this.statusInterval) clearInterval(this.statusInterval)
  },
  computed: {
    ...mapGetters('auth', ['isAuthenticated', 'currentUser'])
  },
  methods: {
    ...mapActions('auth', ['logout']),
    
    async verifyAccountStatus() {
      try {
        await checkStatus(this.currentUser.username)
      } catch (error) {
        if (error.response && error.response.status === 403) {
          this.performForcedLogout('account_disabled')
        }
      }
    },

    performForcedLogout(reason) {
      this.logout()
      
      let msg = 'Your session has ended.'
      if (reason === 'account_disabled') {
        msg = 'Your account has been disabled by an admin.'
      } else if (reason === 'password_changed') {
        msg = 'Your password changed. Please sign in again.'
      }
      
      sessionStorage.setItem('logout_message', msg)
      this.$router.push('/login')
    },

    handleControlMessage(payload) {
      console.warn('App.vue: handleControlMessage executed', payload)
      if (payload.action === 'force_logout') {
        this.performForcedLogout(payload.reason)
      }
    }
  }
}
</script>

<style>
#app, html, body {
  height: 100%;
  margin: 0;
}
#app { min-height: 100vh; }
#app {
  font-family: 'DM Sans', ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #1c1917;
}

/* View transitions – custom spring easing, no ease-in-out */
.view-fade-enter-active { transition: opacity .3s cubic-bezier(0.22, 0.61, 0.36, 1), transform .3s cubic-bezier(0.22, 0.61, 0.36, 1); }
.view-fade-leave-active { transition: opacity .2s cubic-bezier(0.22, 0.61, 0.36, 1), transform .2s cubic-bezier(0.22, 0.61, 0.36, 1); }
.view-fade-enter-from { opacity: 0; transform: translateY(10px); }
.view-fade-leave-to { opacity: 0; transform: translateY(-5px); }
</style>
