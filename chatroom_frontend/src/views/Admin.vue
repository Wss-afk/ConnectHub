<template>
  <div class="admin-page">
    <AppDock />

    <main class="admin-main">
      <section class="admin-shell">
        <header class="admin-hero">
          <div class="admin-hero-copy">
            <span class="admin-kicker">Control room</span>
            <h1 class="admin-title">Admin</h1>
            <p class="admin-subtitle">{{ activeSection.summary }}</p>
          </div>

          <div class="admin-hero-actions">
            <div class="admin-user-card" v-if="currentUser">
              <span class="admin-user-label">Signed in</span>
              <strong class="admin-user-name">{{ currentUser.username }}</strong>
              <span class="admin-user-role">Super admin access</span>
            </div>
            <button type="button" class="admin-logout-btn" @click="logout">Log out</button>
          </div>
        </header>

        <div v-if="!isSuperAdmin" class="admin-warning">
          <h2 class="warning-title">This area is locked.</h2>
          <p class="warning-copy">You need super admin access to open users, groups, and audit records.</p>
        </div>

        <template v-else>
          <nav class="admin-tabs" aria-label="Admin sections">
            <router-link
              v-for="section in adminSections"
              :key="section.path"
              :to="section.path"
              :class="['admin-tab', isActive(section.path) && 'active']"
            >
              <span class="admin-tab-title">{{ section.label }}</span>
              <span class="admin-tab-hint">{{ section.hint }}</span>
            </router-link>
          </nav>

          <section class="admin-stage">
            <div class="admin-stage-head">
              <div>
                <h2 class="admin-stage-title">{{ activeSection.label }}</h2>
                <p class="admin-stage-copy">{{ activeSection.detail }}</p>
              </div>
              <div class="admin-stage-note">{{ activeSection.note }}</div>
            </div>

            <div class="admin-stage-panel">
              <router-view />
            </div>
          </section>
        </template>
      </section>
    </main>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import AppDock from '../components/AppDock.vue'
import { disconnectWebSocket } from '../services/websocket.js'

export default {
  name: 'Admin',
  components: { AppDock },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    isSuperAdmin() {
      return this.currentUser && this.currentUser.role === 'SUPER_ADMIN'
    },
    adminSections() {
      return [
        {
          path: '/admin/users',
          label: 'Users',
          hint: 'Accounts, access, avatars',
          summary: 'Keep access clean. Make dangerous changes obvious.',
          detail: 'Review accounts, reset access, and spot risky edits before they spread.',
          note: 'Identity changes affect every workspace.'
        },
        {
          path: '/admin/groups',
          label: 'Groups',
          hint: 'Teams and membership',
          summary: 'Teams need clear ownership, not hidden member drift.',
          detail: 'Shape group structure, keep membership accurate, and reduce messy routing.',
          note: 'Group edits change who sees what.'
        },
        {
          path: '/admin/audit',
          label: 'Audit',
          hint: 'History and traceability',
          summary: 'When something breaks, the trail should be easy to read.',
          detail: 'Track account actions, confirm who changed what, and keep a clean timeline.',
          note: 'Records matter more than decoration here.'
        }
      ]
    },
    activeSection() {
      return this.adminSections.find(section => this.isActive(section.path)) || this.adminSections[0]
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
.admin-page {
  min-height: 100vh;
  display: flex;
  background:
    radial-gradient(circle at 18% 8%, rgba(15, 118, 110, 0.08), transparent 28%),
    radial-gradient(circle at 85% 12%, rgba(217, 119, 6, 0.08), transparent 24%),
    linear-gradient(145deg, #f7f2ea 0%, #f2eadf 48%, #ede2d4 100%);
}

.admin-main {
  flex: 1;
  min-width: 0;
  padding: 22px 24px 28px;
}

.admin-shell {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.admin-hero {
  display: flex;
  justify-content: space-between;
  align-items: stretch;
  gap: 18px;
  padding: 24px 26px;
  border-radius: 30px;
  border: 1px solid rgba(211, 192, 174, 0.7);
  background: linear-gradient(180deg, rgba(255, 253, 249, 0.96) 0%, rgba(247, 239, 229, 0.92) 100%);
  box-shadow: 0 22px 46px rgba(73, 52, 34, 0.08);
}

.admin-hero-copy {
  max-width: 680px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.admin-kicker {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #9a6b48;
}

.admin-title {
  margin: 0;
  font-size: 48px;
  line-height: 0.94;
  letter-spacing: -0.05em;
  color: #201712;
}

.admin-subtitle {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #735f4d;
}

.admin-hero-actions {
  display: flex;
  align-items: center;
  gap: 24px;
}

.admin-user-card {
  min-width: 210px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 14px 16px;
  border-radius: 20px;
  border: 1px solid rgba(214, 197, 181, 0.82);
  background: rgba(255, 250, 244, 0.82);
}

.admin-user-label {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #9a6b48;
}

.admin-user-name {
  font-size: 18px;
  line-height: 1.1;
  color: #211813;
}

.admin-user-role {
  font-size: 13px;
  font-weight: 600;
  color: #7d6652;
}

.admin-logout-btn {
  margin-left: 2px;
  min-height: 66px;
  padding: 0 22px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(225, 115, 92, 0.28);
  border-radius: 18px;
  background: linear-gradient(135deg, rgba(255, 245, 241, 0.96) 0%, rgba(255, 233, 224, 0.98) 100%);
  color: #b45309;
  font-weight: 700;
  line-height: 1;
  cursor: pointer;
  transition: transform 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), background 0.24s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.admin-logout-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 22px rgba(180, 83, 9, 0.12);
  background: linear-gradient(135deg, rgba(255, 237, 231, 0.98) 0%, rgba(254, 215, 204, 0.98) 100%);
}

.admin-warning {
  padding: 28px 30px;
  border-radius: 28px;
  border: 1px solid rgba(220, 38, 38, 0.18);
  background: linear-gradient(180deg, rgba(255, 248, 246, 0.96) 0%, rgba(255, 241, 236, 0.94) 100%);
  box-shadow: 0 18px 36px rgba(112, 42, 24, 0.08);
}

.warning-title {
  margin: 0 0 6px;
  font-size: 24px;
  color: #341b12;
}

.warning-copy {
  margin: 0;
  max-width: 560px;
  color: #7b6655;
  font-weight: 600;
}

.admin-tabs {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.admin-tab {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 16px 18px;
  border-radius: 22px;
  border: 1px solid rgba(217, 201, 184, 0.72);
  background: rgba(255, 251, 246, 0.76);
  text-decoration: none;
  box-shadow: 0 14px 28px rgba(78, 58, 42, 0.05);
  transition: transform 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), border-color 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), background 0.24s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.admin-tab:hover {
  transform: translateY(-2px);
  border-color: rgba(15, 118, 110, 0.2);
  box-shadow: 0 18px 30px rgba(70, 51, 35, 0.08);
}

.admin-tab.active {
  background: linear-gradient(135deg, rgba(225, 245, 237, 0.96) 0%, rgba(252, 246, 236, 0.98) 100%);
  border-color: rgba(15, 118, 110, 0.26);
  box-shadow: 0 18px 30px rgba(15, 118, 110, 0.1);
}

.admin-tab-title {
  font-size: 18px;
  font-weight: 800;
  letter-spacing: -0.03em;
  color: #201812;
}

.admin-tab-hint {
  font-size: 13px;
  font-weight: 600;
  color: #7b6655;
}

.admin-stage {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.admin-stage-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  padding: 0 6px;
}

.admin-stage-title {
  margin: 0;
  font-size: 30px;
  line-height: 1;
  letter-spacing: -0.04em;
  color: #211913;
}

.admin-stage-copy {
  margin: 6px 0 0;
  font-size: 14px;
  font-weight: 600;
  color: #7a6653;
}

.admin-stage-note {
  max-width: 260px;
  padding: 12px 14px;
  border-radius: 18px;
  background: rgba(255, 248, 239, 0.9);
  border: 1px solid rgba(214, 197, 181, 0.66);
  color: #8a6e58;
  font-size: 13px;
  font-weight: 700;
  text-align: right;
}

.admin-stage-panel {
  border-radius: 30px;
  border: 1px solid rgba(212, 194, 177, 0.7);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.98) 0%, rgba(248, 241, 233, 0.94) 100%);
  box-shadow: 0 24px 46px rgba(75, 54, 36, 0.08);
  padding: 24px;
}

.admin-stage-panel :deep(.text-muted) {
  color: #7b6655 !important;
}

.admin-stage-panel :deep(.alert) {
  border-radius: 18px;
  border: 1px solid rgba(214, 197, 181, 0.72);
  box-shadow: 0 12px 24px rgba(80, 59, 42, 0.05);
}

.admin-stage-panel :deep(.alert-success) {
  background: linear-gradient(180deg, rgba(237, 252, 245, 0.95) 0%, rgba(226, 246, 237, 0.92) 100%);
  color: #14532d;
}

.admin-stage-panel :deep(.alert-danger),
.admin-stage-panel :deep(.alert-warning) {
  background: linear-gradient(180deg, rgba(255, 247, 243, 0.96) 0%, rgba(255, 238, 231, 0.94) 100%);
  color: #7c2d12;
}

.admin-stage-panel :deep(.card),
.admin-stage-panel :deep(.filters-card),
.admin-stage-panel :deep(.table-card) {
  border: 1px solid rgba(214, 197, 181, 0.74);
  border-radius: 24px;
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.96) 0%, rgba(248, 241, 233, 0.9) 100%);
  box-shadow: 0 18px 34px rgba(76, 56, 38, 0.06);
}

.admin-stage-panel :deep(.card-header) {
  padding: 16px 18px;
  border-bottom: 1px solid rgba(214, 197, 181, 0.66);
  background: linear-gradient(180deg, rgba(245, 238, 228, 0.9) 0%, rgba(241, 232, 221, 0.84) 100%);
  color: #261c15;
  font-weight: 800;
}

.admin-stage-panel :deep(.card-body),
.admin-stage-panel :deep(.filters-card),
.admin-stage-panel :deep(.modal-body) {
  color: #241b14;
}

.admin-stage-panel :deep(.form-control),
.admin-stage-panel :deep(.form-select) {
  min-height: 44px;
  border-radius: 14px;
  border: 1px solid rgba(211, 194, 177, 0.82);
  background: rgba(255, 252, 248, 0.94);
  color: #241b14;
}

.admin-stage-panel :deep(.form-control:focus),
.admin-stage-panel :deep(.form-select:focus) {
  border-color: rgba(15, 118, 110, 0.34);
  box-shadow: 0 0 0 4px rgba(15, 118, 110, 0.12);
}

.admin-stage-panel :deep(.btn) {
  min-height: 40px;
  border-radius: 14px;
  font-weight: 700;
  transition: transform 0.22s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.22s cubic-bezier(0.22, 0.61, 0.36, 1), background 0.22s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.admin-stage-panel :deep(.btn:hover) {
  transform: translateY(-1px);
}

.admin-stage-panel :deep(.btn-primary) {
  box-shadow: 0 10px 20px rgba(15, 118, 110, 0.16);
}

.admin-stage-panel :deep(.btn-secondary),
.admin-stage-panel :deep(.btn-outline-secondary) {
  background: linear-gradient(180deg, rgba(243, 236, 228, 0.92) 0%, rgba(233, 223, 211, 0.92) 100%);
  color: #4b3d31;
  border: 1px solid rgba(199, 180, 162, 0.8);
}

.admin-stage-panel :deep(.btn-danger),
.admin-stage-panel :deep(.btn-outline-danger) {
  box-shadow: 0 10px 20px rgba(185, 28, 28, 0.1);
}

.admin-stage-panel :deep(.table) {
  --bs-table-bg: transparent;
  --bs-table-striped-bg: rgba(247, 240, 230, 0.66);
  --bs-table-hover-bg: rgba(228, 245, 238, 0.62);
  margin-bottom: 0;
  color: #241b14;
}

.admin-stage-panel :deep(.table thead th) {
  padding: 14px 16px;
  border-bottom: 1px solid rgba(211, 194, 177, 0.72);
  background: rgba(244, 237, 228, 0.84);
  color: #6a5646;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.admin-stage-panel :deep(.table tbody td) {
  padding: 14px 16px;
  border-color: rgba(223, 209, 193, 0.72);
  vertical-align: middle;
}

.admin-stage-panel :deep(.badge) {
  border-radius: 999px;
  padding: 8px 10px;
  font-weight: 700;
}

.admin-stage-panel :deep(.pagination) {
  gap: 8px;
}

.admin-stage-panel :deep(.page-link) {
  border-radius: 12px;
  border: 1px solid rgba(211, 194, 177, 0.74);
  color: #5c4c40;
  background: rgba(255, 251, 246, 0.88);
}

.admin-stage-panel :deep(.page-item.active .page-link) {
  border-color: rgba(15, 118, 110, 0.24);
  background: linear-gradient(180deg, rgba(227, 245, 238, 0.98) 0%, rgba(214, 239, 229, 0.94) 100%);
  color: #0f766e;
}

.admin-stage-panel :deep(.modal-backdrop),
.admin-stage-panel :deep(.modal-backdrop-custom),
.admin-stage-panel :deep(.password-modal-overlay) {
  backdrop-filter: blur(4px);
}

.admin-stage-panel :deep(.modal-card),
.admin-stage-panel :deep(.modal-custom),
.admin-stage-panel :deep(.password-modal) {
  border-radius: 24px;
  border: 1px solid rgba(214, 197, 181, 0.74);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.98) 0%, rgba(247, 239, 229, 0.96) 100%);
  box-shadow: 0 24px 48px rgba(62, 42, 27, 0.14);
}

@media (max-width: 1100px) {
  .admin-main {
    padding: 18px 16px 24px;
  }

  .admin-hero {
    flex-direction: column;
  }

  .admin-hero-actions,
  .admin-stage-head {
    flex-direction: column;
    align-items: flex-start;
  }

  .admin-user-card {
    min-width: 0;
    width: 100%;
  }

  .admin-stage-note {
    max-width: none;
    width: 100%;
    text-align: left;
  }
}

@media (max-width: 820px) {
  .admin-tabs {
    grid-template-columns: 1fr;
  }

  .admin-title {
    font-size: 38px;
  }

  .admin-stage-panel {
    padding: 18px;
  }
}
</style>
