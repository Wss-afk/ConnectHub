<template>
  <div class="user-list">
    <div v-if="loading" class="skeleton">
      <div v-for="n in 6" :key="'sk-'+n" class="sk-row">
        <div class="sk-avatar"></div>
        <div class="sk-lines">
          <div class="sk-line sk-line-1"></div>
          <div class="sk-line sk-line-2"></div>
        </div>
      </div>
    </div>
    <div v-else-if="otherUsers.length === 0" class="empty">
      <div class="empty-hero" aria-hidden="true">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" opacity=".25" />
          <path d="M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        </svg>
      </div>
      <div class="empty-title">No hay contactos</div>
      <div class="empty-sub">Aún no tienes usuarios disponibles.</div>
      <button class="empty-cta" type="button" @click="$emit('refresh')">Actualizar</button>
    </div>
    <transition-group v-else name="list-fade" tag="ul" class="list">
      <li
        v-for="user in otherUsers"
        :key="user.id"
        @click="$emit('select', user)"
        class="row"
        :class="{ active: selectedUser && selectedUser.id === user.id, online: isUserOnline(user), offline: !isUserOnline(user) }"
      >
        <div class="avatar-wrap">
          <img v-if="user.avatarUrl" :src="user.avatarUrl" class="avatar" :alt="'Avatar de ' + user.username" />
          <div v-else class="avatar placeholder" role="img" :aria-label="'Avatar de ' + user.username">{{ initials(user.username) }}</div>
          <span class="status-dot" :class="isUserOnline(user) ? 'online' : 'offline'" :aria-label="isUserOnline(user) ? 'En línea' : 'Desconectado'" />
        </div>
        <div class="info">
          <div class="top">
            <div class="name">{{ user.username }}</div>
            <div class="time">{{ formattedTime(lastMessageMap[user.id]?.timestamp) }}</div>
          </div>
          <div class="bottom">
            <div class="sub">{{ formatPreview(user.id) }}</div>
            <span v-if="unreadCounts[user.id] > 0" class="unread">{{ unreadCounts[user.id] }}</span>
          </div>
        </div>
      </li>
    </transition-group>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  name: 'UserList',
  props: {
    users: {
      type: Array,
      required: true
    },
    loading: { type: Boolean, default: false },
    unreadCounts: {
      type: Object,
      default: () => ({})
    },
    selectedUser: {
      type: Object,
      default: null
    },
    onlineUsers: {
      type: Array,
      default: () => []
    },
    lastMessageMap: {
      type: Object,
      default: () => ({})
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    otherUsers() {
      return this.users.filter(u => !this.currentUser || u.id !== this.currentUser.id)
    }
  },
  methods: {
    initials(name) {
      const parts = (name || '').trim().split(/\s+/).filter(Boolean)
      return (parts[0] || 'U')[0].toUpperCase()
    },
    formattedTime(ts) {
      if (!ts) return ''
      const d = new Date(ts)
      const now = new Date()
      const sameDay = d.toDateString() === now.toDateString()
      if (sameDay) {
        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }
      const yesterday = new Date(now)
      yesterday.setDate(now.getDate() - 1)
      if (d.toDateString() === yesterday.toDateString()) return 'Ayer'
      return d.toLocaleDateString()
    },
    isUserOnline(user) {
      // Based on real online users list
      if (!Array.isArray(this.onlineUsers) || this.onlineUsers.length === 0) return false
      return this.onlineUsers.some(ou => {
        const ouId = ou.id ?? ou.userId
        return (ouId !== undefined && ouId === user.id) || (ou.username && ou.username === user.username)
      })
    },
    formatPreview(userId) {
      const msg = this.lastMessageMap[userId]
      if (!msg) return '\u00A0'
      const content = msg.content || ''
      if (msg.isMine) {
        return 'Yo: ' + content
      }
      if (msg.senderName) {
        return msg.senderName + ': ' + content
      }
      return content
    }
  }
}
</script>

<style scoped>
.user-list { padding: 0; }

.list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; }

.row {
  padding: 12px 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 12px;
  background: transparent;
  border: none;
  border-bottom: 1px solid rgba(226,232,240,0.5);
  position: relative;
  transition: all .2s cubic-bezier(0.4, 0, 0.2, 1);
}
.row:first-child { border-top: 1px solid rgba(226,232,240,0.5); }
.row:hover { background: linear-gradient(90deg, rgba(79,70,229,0.03) 0%, transparent 100%); transform: translateX(2px); }
.row.active { background: linear-gradient(90deg, rgba(79,70,229,0.06) 0%, rgba(79,70,229,0.02) 100%); }

.row::before {
  content: '';
  position: absolute;
  left: 0; top: 4px; bottom: 4px;
  width: 0;
  background: linear-gradient(180deg, var(--brand-gradient-start), var(--brand-gradient-end));
  transition: width .25s ease;
  border-radius: 0 4px 4px 0;
}
.row:hover::before, .row.active::before { width: 3px; }

.avatar-wrap { position: relative; width: 38px; height: 38px; flex-shrink: 0; }
.avatar { width: 38px; height: 38px; border-radius: 50%; object-fit: cover; box-shadow: 0 2px 6px rgba(0,0,0,0.06); }
.avatar.placeholder { display: inline-flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #e0e7ff, #c7d2fe); color: #4f46e5; font-weight: 700; }
.status-dot { position: absolute; right: -1px; bottom: -1px; width: 11px; height: 11px; border-radius: 50%; box-shadow: 0 0 0 2.5px #fff; }
.status-dot.online { background: #10b981; animation: breathe 2s ease-in-out infinite; }
.status-dot.offline { background: #9ca3af; }

.info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.top { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.bottom { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.name { font-weight: 700; color: #1e293b; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; transition: color .2s ease; }
.time { color: #94a3b8; font-size: 11px; white-space: nowrap; transition: color .2s ease; }
.sub { color: #64748b; font-size: 13px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; transition: color .2s ease; flex: 1; }

.row:hover .name { color: var(--brand-gradient-start); }
.row:hover .time, .row:hover .sub { color: #475569; }

.unread {
  background: linear-gradient(135deg, #f87171, #ef4444); color: #fff; border-radius: 9999px;
  min-width: 20px; height: 20px; padding: 0 6px; display: inline-flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 700; animation: badgePulse 1.4s ease-in-out infinite;
  box-shadow: 0 2px 6px rgba(239, 68, 68, 0.35);
}

@media (max-width: 768px) {
  .user-list { padding: 0; }
  .row { padding: 10px 14px; }
  .avatar-wrap, .avatar { width: 32px; height: 32px; }
  .name { font-size: 13px; }
  .unread { min-width: 18px; height: 18px; font-size: 10px; }
}

@media (max-width: 480px) {
  .row { padding: 8px 12px; }
  .avatar-wrap, .avatar { width: 28px; height: 28px; }
  .name { font-size: 12px; }
}

/* Animaciones */
.list-fade-enter-active, .list-fade-leave-active { transition: all .25s ease; }
.list-fade-enter-from, .list-fade-leave-to { opacity: 0; transform: translateY(6px); }

@keyframes breathe {
  0%, 100% { box-shadow: 0 0 0 2.5px #fff, 0 0 0 0 rgba(16,185,129,0.25); }
  50% { box-shadow: 0 0 0 2.5px #fff, 0 0 0 5px rgba(16,185,129,0.15); }
}

@keyframes badgePulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.08); }
}

/* Skeleton */
.skeleton { display: flex; flex-direction: column; gap: 12px; padding: 8px; }
.sk-row { display: flex; align-items: center; gap: 12px; }
.sk-avatar { width: 38px; height: 38px; border-radius: 50%; background: linear-gradient(90deg, #f1f5f9, #e2e8f0, #f1f5f9); background-size: 200% 100%; animation: shimmer 1.2s infinite; }
.sk-lines { flex: 1; display: flex; flex-direction: column; gap: 6px; }
.sk-line { height: 10px; background: linear-gradient(90deg, #f1f5f9, #e2e8f0, #f1f5f9); background-size: 200% 100%; border-radius: 8px; animation: shimmer 1.2s infinite; }
.sk-line-1 { width: 40%; }
.sk-line-2 { width: 60%; opacity: .9; }
@keyframes shimmer { 0% { background-position: -200px 0; } 100% { background-position: 200px 0; } }

/* Empty state */
.empty { text-align: center; padding: 24px 16px; color: #64748b; }
.empty-hero { display: inline-flex; align-items: center; justify-content: center; color: #94a3b8; margin-bottom: 10px; background: #f1f5f9; padding: 16px; border-radius: 50%; }
.empty-title { font-weight: 700; color: #334155; font-size: 0.95rem; }
.empty-sub { font-size: 12px; margin-top: 4px; color: #94a3b8; }
.empty-cta { margin-top: 12px; padding: 8px 16px; border-radius: 10px; border: 1px solid rgba(79,70,229,0.2); background: linear-gradient(135deg, #eef2ff, #e0e7ff); color: #4f46e5; font-weight: 700; cursor: pointer; transition: all 0.2s; }
.empty-cta:hover { background: linear-gradient(135deg, #e0e7ff, #c7d2fe); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(79,70,229,0.15); }
</style>
