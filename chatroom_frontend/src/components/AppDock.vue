<template>
  <aside class="app-dock" aria-label="Aplicaciones">
    <div class="brand">
      <svg class="brand-logo" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <defs>
          <linearGradient id="ch-grad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stop-color="var(--brand-gradient-start)"/>
            <stop offset="100%" stop-color="var(--brand-gradient-end)"/>
          </linearGradient>
        </defs>
        <!-- Logo moderno inventado: triángulo dinámico + círculo acento -->
        <polygon points="12,46 52,34 22,12" fill="url(#ch-grad)" opacity="0.95"/>
        <circle cx="46" cy="18" r="7" fill="var(--brand-gradient-end)" opacity="0.9"/>
      </svg>
      <span class="brand-name">ConnectHub</span>
    </div>
    <ul class="menu">
      <li v-for="item in items" :key="item.label" :class="['menu-item', isActive(item.path) && 'active']" @click="go(item.path)" :aria-label="item.label">
        <Icon :name="item.icon" :size="24" class="menu-icon" />
        <span class="label">{{ item.label }}</span>
      </li>
    </ul>
    <div class="dock-footer">
      <div v-if="currentUser" class="current-user" aria-label="Usuario conectado">
        <img v-if="currentUser.avatarUrl" :src="currentUser.avatarUrl" class="cu-avatar" @click="openAvatarPreview" />
        <div v-else class="cu-avatar placeholder" title="Añadir avatar" @click="triggerAvatarChange">
          <span class="cu-initial">{{ avatarInitial() }}</span>
        </div>
        <div class="cu-info">
          <div class="cu-name">{{ currentUser.username }}</div>
          <div class="cu-sub">Conectado</div>
        </div>
        <input ref="avatarInput" type="file" accept="image/*" style="display:none" @change="handleAvatarSelected" />
      </div>
      <div class="footer-divider" aria-hidden="true"></div>
      <button type="button" class="logout-btn" aria-label="Cerrar sesión" @click="logout">Cerrar sesión</button>
    </div>
    <div v-if="avatarPreviewOpen && currentUser && currentUser.avatarUrl" class="modal-backdrop" @click.self="closeAvatarPreview">
      <div class="modal-card">
        <img :src="currentUser.avatarUrl" class="avatar-preview" alt="Avatar" />
        <div class="modal-actions">
          <button type="button" class="modal-btn" @click="triggerAvatarChange">Cambiar avatar</button>
          <button type="button" class="modal-btn" @click="removeAvatar">Quitar avatar</button>
          <button type="button" class="modal-btn" @click="closeAvatarPreview">Cerrar</button>
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
import Icon from './Icon.vue'
export default {
  name: 'AppDock',
  components: { Icon },
  data() {
    return { avatarPreviewOpen: false }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    items() {
      // Si es SUPER_ADMIN, limitar el dock al panel de admin
      if (this.currentUser && this.currentUser.role === 'SUPER_ADMIN') {
        return [
          { label: 'Admin', icon: 'shield', path: '/admin' }
        ]
      }
      return [
        { label: 'Inicio', icon: 'home', path: '/home' },
        { label: 'Eventos', icon: 'calendar', path: '/events' },
        { label: 'Mensajes', icon: 'message-square', path: '/chat' }
      ]
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
        console.error('Error al ejecutar logout en store:', e)
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
          alert('Selecciona una imagen válida para tu avatar')
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
        console.error('Error actualizando avatar:', e)
        alert('No se pudo actualizar el avatar')
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
        console.error('Error quitando avatar:', e)
        alert('No se pudo quitar el avatar')
      }
    },
    avatarInitial() {
      const n = (this.currentUser && this.currentUser.username) || ''
      return n ? n.charAt(0).toUpperCase() : '👤'
    }
  }
  
}
</script>

<style scoped>
.app-dock {
  flex: 0 0 260px;
  background: linear-gradient(180deg, #ffffff 0%, #f8faff 100%);
  border-right: 1px solid rgba(226, 232, 240, 0.6);
  display: flex;
  flex-direction: column;
  padding: 16px 20px;
  height: 100vh;
  overflow-y: auto;
  margin-right: 0;
  position: sticky; top: 0;
  z-index: 1000;
  box-shadow: 4px 0 24px rgba(0,0,0,0.03);
}

.brand {
  display: flex; align-items: center; gap: 14px;
  padding: 12px 4px 24px 4px;
  border-bottom: 1px solid rgba(226,232,240,0.6);
  margin-bottom: 24px;
}
.brand-logo { width: 36px; height: 36px; filter: drop-shadow(0 4px 10px rgba(79,70,229,.25)); transition: transform 0.3s ease; }
.brand-logo:hover { transform: rotate(-8deg) scale(1.08); }
.brand-name {
  font-size: 22px; font-weight: 800; letter-spacing: -0.5px;
  background: linear-gradient(135deg, #1e293b 0%, #4f46e5 100%);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}

.menu { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
.menu-item {
  display: flex; align-items: center; gap: 14px;
  padding: 14px 16px; border-radius: 14px; cursor: pointer;
  color: #64748b; background: transparent; transition: all .25s cubic-bezier(0.4, 0, 0.2, 1);
  font-weight: 600; position: relative; overflow: hidden;
}
.menu-item .icon { width: 24px; text-align: center; font-size: 20px; display: flex; align-items: center; justify-content: center; }
.menu-item .label { font-weight: 600; font-size: 0.95rem; letter-spacing: 0.2px; }
.menu-item:hover { background: rgba(79,70,229,0.04); color: #334155; transform: translateX(4px); }
.menu-item.active {
  color: var(--brand-gradient-start);
  background: linear-gradient(135deg, #eff6ff 0%, #eef2ff 100%);
  box-shadow: 0 4px 16px rgba(79, 70, 229, 0.12), inset 0 0 0 1px rgba(79,70,229,0.08);
}
.menu-item.active::before {
  content: ''; position: absolute; left: 0; top: 8px; bottom: 8px; width: 3px;
  background: linear-gradient(180deg, var(--brand-gradient-start), var(--brand-gradient-end));
  border-radius: 0 4px 4px 0;
}

.dock-footer {
  margin-top: auto;
  padding: 24px 0 16px;
  background: transparent;
}
.logout-btn {
  width: 100%;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(239,68,68,0.15);
  background: linear-gradient(135deg, #fef2f2 0%, #fff1f2 100%);
  color: #ef4444;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.25s ease;
}
.logout-btn:hover { background: linear-gradient(135deg, #fee2e2 0%, #fecdd3 100%); color: #dc2626; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(239,68,68,0.15); }

/* Tarjeta de usuario actual */
.current-user {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
  padding: 10px 12px;
  border-radius: 14px;
  background: linear-gradient(135deg, #ffffff 0%, #f8faff 100%);
  border: 1px solid rgba(79,70,229,0.1);
  color: #334155;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
  transition: all 0.25s ease;
}
.current-user:hover { box-shadow: 0 4px 16px rgba(79,70,229,0.1); border-color: rgba(79,70,229,0.2); transform: translateY(-1px); }
.cu-avatar { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; border: 2px solid rgba(79,70,229,0.15); box-shadow: 0 2px 8px rgba(79,70,229,0.1); }
.cu-avatar.placeholder { display:flex; align-items:center; justify-content:center; background: linear-gradient(135deg, #e0e7ff, #c7d2fe); color:#4f46e5; cursor:pointer; }
.cu-initial { font-weight: 800; }
.cu-info { flex: 1; min-width: 0; }
.cu-name { font-weight: 700; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: #1e293b; }
.cu-sub { font-size: 12px; color: #10b981; font-weight: 600; display: flex; align-items: center; gap: 4px; }
.cu-sub::before { content: ''; width: 6px; height: 6px; border-radius: 50%; background: #10b981; display: inline-block; }

.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; z-index: 1050; backdrop-filter: blur(4px); }
.modal-card { background: #fff; border-radius: 16px; padding: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.2); max-width: 90vw; animation: modalPop 0.2s ease-out; }
@keyframes modalPop { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }
.avatar-preview { max-width: 56vw; max-height: 70vh; display: block; border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.15); }
.modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 14px; }
.modal-btn { padding: 8px 14px; border-radius: 10px; border: 1px solid var(--border-color); background: #f8fafc; cursor: pointer; font-weight: 600; transition: all 0.2s; }
.modal-btn:hover { background: #e2e8f0; transform: translateY(-1px); }

/* Línea divisoria */
.footer-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(148,163,184,0.3), transparent);
  margin: 10px 0 12px;
}

@media (max-width: 768px) {
  .app-dock { display: none; }
}
</style>
