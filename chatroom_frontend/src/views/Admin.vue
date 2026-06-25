<template>
  <div class="admin-container">
    <div class="admin-header d-flex align-items-center justify-content-between">
      <h2 class="m-0">Super Admin Panel</h2>
      <div class="admin-actions d-flex align-items-center">
        <span v-if="currentUser" class="badge bg-primary">{{ currentUser.username }}</span>
        <button type="button" class="admin-logout-btn btn btn-sm ms-2" @click="logout">Log out</button>
      </div>
    </div>

    <div v-if="!isSuperAdmin" class="alert alert-warning">You don't have SUPER_ADMIN permissions.</div>

    <div v-else>
      <ul class="nav nav-tabs mb-3">
        <li class="nav-item">
          <router-link class="nav-link" :class="{ active: isActive('/admin/users') }" to="/admin/users">Users</router-link>
        </li>
        <li class="nav-item">
          <router-link class="nav-link" :class="{ active: isActive('/admin/groups') }" to="/admin/groups">Groups</router-link>
        </li>
        <li class="nav-item">
          <router-link class="nav-link" :class="{ active: isActive('/admin/audit') }" to="/admin/audit">Audit</router-link>
        </li>
      </ul>

      <div class="card">
        <div class="card-body">
          <router-view />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import { disconnectWebSocket } from '../services/websocket.js'

export default {
  name: 'Admin',
  computed: {
    ...mapGetters('auth', ['currentUser']),
    isSuperAdmin() {
      return this.currentUser && this.currentUser.role === 'SUPER_ADMIN'
    }
  },
  methods: {
    isActive(path) {
      return this.$route.path.startsWith(path)
    },
    logout() {
      try {
        this.$store.dispatch('auth/logout')
      } catch (e) {
        console.error('Error executing logout in store:', e)
      }
      try {
        disconnectWebSocket()
      } catch (e) {
        console.error('Error closing WebSocket:', e)
      }
      this.$router.push('/login')
    }
  }
}
</script>

<style scoped>
.admin-container {
  max-width: 1100px;
  margin: 24px auto;
  padding: 16px;
}
.admin-actions { gap: 8px; }
.nav-link {
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
  border-radius: 10px 10px 0 0;
  font-weight: 600;
}
.nav-link:hover {
  background: rgba(15,118,110,0.04);
}
.nav-link.active {
  background: linear-gradient(135deg, #f0fdf4 0%, #d1fae5 100%) !important;
  color: #0f766e !important;
  border-color: transparent !important;
  box-shadow: 0 -2px 8px rgba(15,118,110,0.08);
}
.admin-logout-btn {
  background: linear-gradient(135deg, #292524 0%, #1c1917 100%);
  color: #ffffff;
  border: none;
  padding: 6px 14px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.admin-logout-btn:hover {
  background: linear-gradient(135deg, #1c1917 0%, #0f172a 100%);
  color: #ffffff;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}
</style>