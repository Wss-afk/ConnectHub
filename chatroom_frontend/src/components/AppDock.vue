<template>
  <aside class="app-dock" aria-label="Applications">
    <div class="brand">
      <BrandMark class="brand-logo" :size="40" />
      <div class="brand-copy">
        <span class="brand-kicker">{{ dockKicker }}</span>
        <span class="brand-name">ConnectHub</span>
        <p class="brand-sub">{{ activeLabel }}</p>
      </div>
    </div>
    <div class="menu-shell">
      <div class="menu-title">Workspace</div>
      <ul class="menu">
        <li
          v-for="item in items"
          :key="item.label"
          :class="['menu-item', isActive(item.path) && 'active']"
          @click="go(item.path)"
          :aria-label="item.label"
        >
          <span class="menu-icon-wrap">
            <Icon :name="item.icon" :size="20" class="menu-icon" />
          </span>
          <span class="menu-copy">
            <span class="label">{{ item.label }}</span>
            <span class="hint">{{ item.hint }}</span>
          </span>
        </li>
      </ul>
    </div>
    <div class="dock-footer">
      <div v-if="currentUser" class="current-user" aria-label="Current user">
        <img v-if="currentUser.avatarUrl" :src="currentUser.avatarUrl" class="cu-avatar" @click="openAvatarPreview" />
        <div v-else class="cu-avatar placeholder" title="Add avatar" @click="triggerAvatarChange">
          <span class="cu-initial">{{ avatarInitial() }}</span>
        </div>
        <div class="cu-info">
          <div class="cu-name">{{ currentUser.username }}</div>
          <div class="cu-sub">{{ roleLabel }}</div>
        </div>
        <span class="status-dot" aria-hidden="true"></span>
        <input ref="avatarInput" type="file" accept="image/*" style="display:none" @change="handleAvatarSelected" />
      </div>
      <div class="footer-divider" aria-hidden="true"></div>
      <button type="button" class="logout-btn" aria-label="Sign out" @click="logout">Sign out</button>
    </div>
    <div v-if="avatarPreviewOpen && currentUser && currentUser.avatarUrl" class="modal-backdrop" @click.self="closeAvatarPreview">
      <div class="modal-card">
        <img :src="currentUser.avatarUrl" class="avatar-preview" alt="Avatar" />
        <div class="modal-actions">
          <button type="button" class="modal-btn" @click="triggerAvatarChange">Change avatar</button>
          <button type="button" class="modal-btn" @click="removeAvatar">Remove avatar</button>
          <button type="button" class="modal-btn" @click="closeAvatarPreview">Close</button>
        </div>
      </div>
    </div>
  </aside>
</template>

<script>
import { mapGetters } from 'vuex'
import { disconnectWebSocket } from '../services/websocket.js'
import { uploadAvatar } from '../services/chat.service.js'
import { updateAvatar } from '../services/user.service.js'
import BrandMark from './BrandMark.vue'
import Icon from './Icon.vue'
export default {
  name: 'AppDock',
  components: { BrandMark, Icon },
  data() {
    return { avatarPreviewOpen: false }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    items() {
      if (this.currentUser && this.currentUser.role === 'SUPER_ADMIN') {
        return [
          { label: 'Admin', hint: 'Users, groups, audit', icon: 'shield', path: '/admin' }
        ]
      }
      return [
        { label: 'Home', hint: 'Today board and updates', icon: 'home', path: '/home' },
        { label: 'Events', hint: 'Calendar and task blocks', icon: 'calendar', path: '/events' },
        { label: 'Messages', hint: 'Chats and unread threads', icon: 'message-square', path: '/chat' }
      ]
    },
    activeLabel() {
      const activeItem = this.items.find(item => this.isActive(item.path))
      return activeItem ? activeItem.hint : 'Team workspace'
    },
    dockKicker() {
      return this.currentUser && this.currentUser.role === 'SUPER_ADMIN' ? 'Control room' : 'Today first'
    },
    roleLabel() {
      return this.currentUser && this.currentUser.role === 'SUPER_ADMIN' ? 'Super admin' : 'Online now'
    }
  },
  methods: {
    go(path) {
      if (!path) return
      const exists = this.$router && this.$router.getRoutes && this.$router.getRoutes().some(r => r.path === path)
      if (exists && this.$route.path !== path) this.$router.push(path)
    },
    isActive(path) {
      if (!path || !this.$route) return false
      return this.$route.path === path || this.$route.path.startsWith(path)
    },
    logout() {
      try {
        this.$store.dispatch('auth/logout')
      } catch (e) {
        console.error('Logout store error:', e)
      }
      disconnectWebSocket()
      this.$router.push('/login')
    },
    openAvatarPreview() {
      this.avatarPreviewOpen = true
    },
    closeAvatarPreview() {
      this.avatarPreviewOpen = false
    },
    triggerAvatarChange() {
      const el = this.$refs.avatarInput
      if (el) el.click()
    },
    async handleAvatarSelected(evt) {
      try {
        const file = evt.target.files && evt.target.files[0]
        if (!file) return
        const res = await uploadAvatar(file)
        const { url, type } = res.data || {}
        if (!url || type !== 'image') {
          alert('Please select a valid image for your avatar')
          return
        }
        const userId = this.currentUser && this.currentUser.id
        if (!userId) return
        const upd = await updateAvatar(userId, url)
        const updatedUser = upd?.data || { ...this.currentUser, avatarUrl: url }
        this.$store.commit('auth/SET_USER', updatedUser)
        evt.target.value = ''
        this.avatarPreviewOpen = false
      } catch (e) {
        console.error('Error updating avatar:', e)
        alert('Could not update avatar')
      }
    },
    async removeAvatar() {
      try {
        const userId = this.currentUser && this.currentUser.id
        if (!userId) return
        const upd = await updateAvatar(userId, '')
        const updatedUser = upd?.data || { ...this.currentUser, avatarUrl: null }
        this.$store.commit('auth/SET_USER', updatedUser)
        this.avatarPreviewOpen = false
      } catch (e) {
        console.error('Error removing avatar:', e)
        alert('Could not remove avatar')
      }
    },
    avatarInitial() {
      const n = (this.currentUser && this.currentUser.username) || ''
      return n ? n.charAt(0).toUpperCase() : '?'
    }
  }
}
</script>

<style scoped>
.app-dock {
  flex: 0 0 284px;
  background:
    radial-gradient(circle at 16% 10%, rgba(15, 118, 110, 0.08), transparent 24%),
    radial-gradient(circle at 88% 12%, rgba(217, 119, 6, 0.08), transparent 20%),
    linear-gradient(180deg, #fcfaf6 0%, #f5efe7 100%);
  border-right: 1px solid rgba(214, 197, 181, 0.72);
  display: flex;
  flex-direction: column;
  padding: 18px 18px 20px;
  height: 100vh;
  overflow-y: auto;
  margin-right: 0;
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: 10px 0 36px rgba(42, 29, 18, 0.06);
}

.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 10px 8px 20px;
  border-bottom: 1px solid rgba(214, 197, 181, 0.72);
  margin-bottom: 18px;
}

.brand-logo {
  width: 40px;
  height: 40px;
  flex: 0 0 40px;
  filter: drop-shadow(0 10px 18px rgba(15, 118, 110, 0.18));
  transition: transform 0.28s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.brand-logo:hover {
  transform: rotate(-7deg) translateY(-1px);
}

.brand-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.brand-kicker {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #9a6b48;
}

.brand-name {
  font-size: 21px;
  font-weight: 800;
  letter-spacing: -0.04em;
  background: linear-gradient(135deg, #1c1917 0%, #0f766e 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.brand-sub {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #786656;
  line-height: 1.35;
}

.menu-shell {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.menu-title {
  padding: 0 8px;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #8f735c;
}

.menu {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 13px 14px;
  border-radius: 18px;
  cursor: pointer;
  color: #53483f;
  background: rgba(255, 251, 246, 0.34);
  border: 1px solid rgba(223, 210, 197, 0.2);
  transition: transform 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), background 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), border-color 0.24s cubic-bezier(0.22, 0.61, 0.36, 1), color 0.24s cubic-bezier(0.22, 0.61, 0.36, 1);
  position: relative;
  overflow: hidden;
}

.menu-icon-wrap {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(145deg, rgba(255, 252, 248, 0.95), rgba(244, 235, 224, 0.72));
  border: 1px solid rgba(219, 200, 182, 0.6);
  color: #665344;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.7);
}

.menu-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.menu-item .label {
  font-weight: 700;
  font-size: 15px;
  letter-spacing: -0.01em;
}

.hint {
  font-size: 12px;
  font-weight: 600;
  color: #8a7562;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.menu-item:hover {
  background: rgba(255, 251, 246, 0.78);
  color: #1c1917;
  transform: translateX(3px);
  box-shadow: 0 12px 26px rgba(80, 60, 42, 0.08);
  border-color: rgba(15, 118, 110, 0.18);
}

.menu-item.active {
  color: #134e4a;
  background: linear-gradient(135deg, rgba(226, 246, 237, 0.96) 0%, rgba(247, 240, 229, 0.98) 100%);
  border-color: rgba(15, 118, 110, 0.22);
  box-shadow: 0 16px 28px rgba(15, 118, 110, 0.1), inset 0 0 0 1px rgba(255, 255, 255, 0.46);
}

.menu-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 9px;
  bottom: 9px;
  width: 3px;
  background: linear-gradient(180deg, var(--brand-gradient-start), var(--brand-gradient-end));
  border-radius: 0 4px 4px 0;
}

.menu-item.active .menu-icon-wrap {
  color: #0f766e;
  border-color: rgba(15, 118, 110, 0.24);
  background: linear-gradient(145deg, rgba(245, 255, 251, 0.96), rgba(225, 245, 237, 0.9));
}

.menu-item.active .hint {
  color: #5d736e;
}

.dock-footer {
  margin-top: auto;
  padding: 22px 0 10px;
  background: transparent;
}

.logout-btn {
  width: 100%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 12px 14px;
  border-radius: 16px;
  border: 1px solid rgba(225, 115, 92, 0.24);
  background: linear-gradient(135deg, rgba(255, 245, 241, 0.94) 0%, rgba(255, 237, 231, 0.98) 100%);
  color: #c2410c;
  font-weight: 700;
  line-height: 1;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.logout-btn:hover {
  background: linear-gradient(135deg, rgba(255, 236, 229, 0.98) 0%, rgba(254, 215, 204, 0.98) 100%);
  color: #9a3412;
  transform: translateY(-1px);
  box-shadow: 0 10px 18px rgba(194, 65, 12, 0.12);
}

.current-user {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
  padding: 12px 12px;
  border-radius: 18px;
  background: linear-gradient(145deg, rgba(255, 252, 248, 0.94) 0%, rgba(248, 241, 233, 0.96) 100%);
  border: 1px solid rgba(210, 193, 176, 0.72);
  color: #1c1917;
  box-shadow: 0 12px 24px rgba(54, 37, 25, 0.06);
  transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.current-user:hover {
  box-shadow: 0 16px 30px rgba(15, 118, 110, 0.08);
  border-color: rgba(15, 118, 110, 0.2);
  transform: translateY(-1px);
}

.cu-avatar {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  object-fit: cover;
  border: 1px solid rgba(15, 118, 110, 0.18);
  box-shadow: 0 6px 14px rgba(15, 118, 110, 0.1);
}

.cu-avatar.placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #d9f2ea, #bfe9d9);
  color: #0f766e;
  cursor: pointer;
}

.cu-initial { font-weight: 800; }
.cu-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 3px;
  align-self: stretch;
}
.cu-name {
  font-weight: 700;
  font-size: 14px;
  line-height: 1.05;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #1c1917;
}

.cu-sub {
  font-size: 12px;
  line-height: 1.15;
  color: #7b6856;
  font-weight: 600;
}

.status-dot {
  width: 10px;
  height: 10px;
  flex: 0 0 10px;
  border-radius: 999px;
  background: #16a34a;
  box-shadow: 0 0 0 4px rgba(22, 163, 74, 0.12);
}

.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; z-index: 1050; backdrop-filter: blur(4px); }
.modal-card { background: #fefdfb; border-radius: 16px; padding: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.2); max-width: 90vw; animation: modalPop 0.2s cubic-bezier(0.22, 0.61, 0.36, 1); }
@keyframes modalPop { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }
.avatar-preview { max-width: 56vw; max-height: 70vh; display: block; border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.15); }
.modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 14px; }
.modal-btn { padding: 8px 14px; border-radius: 10px; border: 1px solid var(--border-color); background: #faf8f5; cursor: pointer; font-weight: 600; transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1); }
.modal-btn:hover { background: #e7e5e4; transform: translateY(-1px); }

.footer-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(161, 137, 117, 0.34), transparent);
  margin: 12px 0 14px;
}

@media (max-width: 768px) {
  .app-dock { display: none; }
}
</style>
