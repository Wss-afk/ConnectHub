<template>
  <div class="chat-window">
    <div class="chat-topbar" v-if="chatUser && chatType === 'user'">
      <div class="chat-context">
        <div
          class="chat-avatar"
          :title="chatUser.username"
          role="img"
          :aria-label="'Avatar of ' + ((chatUser && (chatUser.username || chatUser.name)) || 'user')"
        >
          <img v-if="chatUser && chatUser.avatarUrl" :src="chatUser.avatarUrl" alt="avatar" class="avatar-img" />
          <span v-else>{{ userInitial }}</span>
        </div>
        <div class="chat-meta">
          <div class="chat-name">{{ chatUser.username }}</div>
          <div class="chat-sub">{{ chatUser.email || chatUser.userEmail || 'Private chat' }}</div>
        </div>
      </div>
      <div class="chat-tools">
        <input
          type="text"
          class="chat-search"
          placeholder="Search this chat"
          aria-label="Search"
          :value="searchQuery"
          @input="onInputSearch"
          @keyup.enter="$emit('search', localSearch)"
        />
      </div>
    </div>
    <div class="chat-topbar" v-else-if="chatGroup && chatType === 'group'">
      <div class="chat-context">
        <div class="chat-avatar group" :title="chatGroup.name">{{ groupInitial }}</div>
        <div class="chat-meta">
          <div class="chat-name">{{ chatGroup.name }}</div>
          <div class="chat-sub">{{ (chatGroup.users && chatGroup.users.length) ? (chatGroup.users.length + ' members') : 'Group' }}</div>
        </div>
      </div>
      <div class="chat-tools">
        <input
          type="text"
          class="chat-search"
          placeholder="Search this group"
          aria-label="Search"
          :value="searchQuery"
          @input="onInputSearch"
          @keyup.enter="$emit('search', localSearch)"
        />
      </div>
    </div>
    <div v-if="chatGroup && chatType === 'group'" class="group-members-bar">
      <span class="members-title">Members:</span>
      <div class="members-list">
        <span v-for="u in (chatGroup.users || [])" :key="u.id" class="member-chip">{{ u.username }}</span>
        <span v-if="!chatGroup.users || chatGroup.users.length === 0" class="member-chip empty">No members</span>
      </div>
    </div>
    <div
      class="messages"
      ref="messagesContainer"
      @scroll="onScroll"
      role="log"
      aria-live="polite"
      aria-relevant="additions"
      aria-atomic="false"
      aria-label="Chat messages"
    >
      <div v-if="loading" class="messages-skeleton">
        <div v-for="n in 6" :key="'skm-'+n" class="sk-msg" :class="n % 2 === 0 ? 'left' : 'right'">
          <div class="sk-bubble"></div>
        </div>
      </div>
      <div v-else-if="(messages && messages.length === 0)" class="messages-empty">
        <div class="empty-card" role="region" aria-label="No messages">
          <div class="empty-hero" aria-hidden="true">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 5.5A3.5 3.5 0 0 1 7.5 2h9A3.5 3.5 0 0 1 20 5.5v7A3.5 3.5 0 0 1 16.5 16H13l-3.5 3.5c-.6.6-1.5.18-1.5-.7V16H7.5A3.5 3.5 0 0 1 4 12.5v-7Z" fill="currentColor"/>
            </svg>
          </div>
          <div class="empty-title">No messages yet</div>
          <div class="empty-sub">Send your first message to start the conversation.</div>
          <button type="button" class="empty-cta" @click="$emit('compose')">Write a message</button>
        </div>
      </div>
      <transition-group v-else name="msg" tag="div" class="messages-list">
        <component
          v-for="(item, idx) in windowedItems"
          :is="item.type === 'separator' ? 'DateSeparator' : 'MessageItem'"
          :key="item.key || idx"
          v-bind="item.type === 'separator' 
            ? { label: item.label } 
            : { message: item.message, currentUserId: currentUserId, continuation: item.continuation, highlightQuery: searchQuery }"
        />
      </transition-group>
    </div>

    <button
      v-if="!isAtBottom"
      class="scroll-bottom-btn"
      @click="jumpToBottom"
      aria-label="Jump to latest"
    >
      ↓ Jump to latest
    </button>

    <div
      v-if="unreadCount > 0 && !shouldAutoScroll"
      class="new-messages-banner"
      @click="jumpToBottom"
      aria-live="polite"
    >
      New messages · {{ unreadCount }}
    </div>

    <div class="composer-bar">
      <slot></slot>
    </div>
  </div>
</template>

<script>
import MessageItem from './MessageItem.vue'
import DateSeparator from './DateSeparator.vue'

export default {
  name: 'ChatWindow',
  components: { MessageItem, DateSeparator },
  props: {
    messages: { type: Array, required: true },
    chatUser: { type: Object, default: null },
    chatGroup: { type: Object, default: null },
    chatType: { type: String, default: 'user' },
    currentUserId: { type: [String, Number], required: true },
    searchQuery: { type: String, default: '' },
    loading: { type: Boolean, default: false }
  },
  data() {
    return {
      startIndex: 0,
      windowSize: 120,
      prependCount: 60,
      shouldAutoScroll: true,
      isAtBottom: true,
      nearBottomThreshold: 150,
      unreadCount: 0,
      lastMessagesLength: 0,
      localSearch: ''
    }
  },
  computed: {
    allItems() {
      return this.decorateMessages(this.messages || [])
    },
    windowedItems() {
      const end = this.allItems.length
      const start = Math.max(0, Math.min(this.startIndex, end))
      return this.allItems.slice(start, end)
    },
    userInitial() {
      const name = (this.chatUser && (this.chatUser.username || this.chatUser.name)) || ''
      return name ? name.charAt(0).toUpperCase() : '?'
    },
    groupInitial() {
      const name = (this.chatGroup && this.chatGroup.name) || ''
      return name ? name.charAt(0).toUpperCase() : '#'
    }
  },
  watch: {
    messages: {
      immediate: true,
      handler(newVal, oldVal) {
        const prevLen = Array.isArray(oldVal) ? oldVal.length : this.lastMessagesLength || 0
        const currLen = Array.isArray(newVal) ? newVal.length : 0
        const end = this.allItems.length

        if (this.shouldAutoScroll) {
          this.startIndex = Math.max(0, end - this.windowSize)
          this.$nextTick(() => this.scrollToBottom())
          this.unreadCount = 0
        } else {
          if (currLen > prevLen) {
            const added = Array.isArray(newVal) ? newVal.slice(prevLen) : []
            const newlyFromOthers = added.filter(m => {
              const sid = (m && m.sender && (m.sender.id ?? m.sender.userId)) || m.senderId
              return sid != this.currentUserId
            }).length
            this.unreadCount += newlyFromOthers
          }
          // Mantener ventana estable cuando el usuario está leyendo arriba
        }
        this.lastMessagesLength = currLen
      }
    }
  },
  methods: {
    recalcWindowSize() {
      const el = this.$refs.messagesContainer
      if (!el) return
      const vh = el.clientHeight || 600
      const approxItem = 56
      const visibleCount = Math.max(60, Math.floor(vh / approxItem) * 2)
      this.windowSize = visibleCount
      this.prependCount = Math.max(30, Math.floor(visibleCount / 2))
    },
    onInputSearch(e) {
      const val = e && e.target ? e.target.value : ''
      this.localSearch = val
      this.$emit('update:searchQuery', val)
    },
    onScroll() {
      this.updateAutoScrollState()
      const el = this.$refs.messagesContainer
      if (!el) return

      // Carga progresiva de mensajes más antiguos cuando se acerca al top
      if (el.scrollTop < 50 && this.startIndex > 0) {
        const prevScrollHeight = el.scrollHeight
        const prevTop = el.scrollTop
        this.startIndex = Math.max(0, this.startIndex - this.prependCount)
        this.$nextTick(() => {
          const newScrollHeight = el.scrollHeight
          // Mantener la posición visible del usuario
          el.scrollTop = newScrollHeight - prevScrollHeight + prevTop
          this.updateAutoScrollState()
        })
      }
    },
    scrollToBottom() {
      const el = this.$refs.messagesContainer
      if (!el) return
      el.scrollTop = el.scrollHeight
      this.updateAutoScrollState()
    },
    jumpToBottom() {
      this.shouldAutoScroll = true
      this.unreadCount = 0
      this.$nextTick(() => {
        this.scrollToBottom()
        this.updateAutoScrollState()
      })
    },
    decorateMessages(list) {
      const result = []
      let lastDayKey = null
      let prevMsg = null
      const CONTINUATION_MS = 5 * 60 * 1000 // 5 minutos para agrupar visualmente
      list.forEach((msg, i) => {
        const ts = msg.timestamp ? new Date(msg.timestamp) : new Date()
        const dayKey = `${ts.getFullYear()}-${ts.getMonth()+1}-${ts.getDate()}`
        if (dayKey !== lastDayKey) {
          result.push({ type: 'separator', label: this.formatDateLabel(ts), key: `sep-${dayKey}` })
          lastDayKey = dayKey
        }
        let continuation = false
        if (prevMsg) {
          const prevTs = prevMsg.timestamp ? new Date(prevMsg.timestamp) : ts
          const prevSender = (prevMsg.sender && (prevMsg.sender.id ?? prevMsg.sender.userId)) ?? prevMsg.senderId ?? prevMsg.sender
          const currSender = (msg.sender && (msg.sender.id ?? msg.sender.userId)) ?? msg.senderId ?? msg.sender
          const closeInTime = Math.abs(ts - prevTs) <= CONTINUATION_MS
          continuation = prevSender == currSender && closeInTime
        }
        result.push({ type: 'message', message: msg, continuation, key: `msg-${msg.id ?? i}` })
        prevMsg = msg
      })
      return result
    },
    formatDateLabel(date) {
      const d = new Date(date)
      const today = new Date()
      const yesterday = new Date()
      yesterday.setDate(today.getDate() - 1)

      const sameDay = (a,b) => a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate()
      if (sameDay(d, today)) return 'Today'
      if (sameDay(d, yesterday)) return 'Yesterday'
      return d.toLocaleDateString('en-US', { day: '2-digit', month: 'short', year: 'numeric' })
    },
    updateAutoScrollState() {
      const el = this.$refs.messagesContainer
      if (!el) return
      const distance = el.scrollHeight - el.scrollTop - el.clientHeight
      const atBottom = distance <= 2
      this.isAtBottom = atBottom
      this.shouldAutoScroll = atBottom
    }
  },
  mounted() {
    this.$nextTick(() => {
      this.scrollToBottom()
      this.updateAutoScrollState()
      this.recalcWindowSize()
      window.addEventListener('resize', this.recalcWindowSize, { passive: true })
    })
  }
}
</script>

<style scoped>
.chat-window {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, #faf8f5 0%, #ffffff 100%);
  border-radius: 16px;
  padding: 20px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(15,118,110,0.05), 0 1px 3px rgba(0,0,0,0.03);
  border: 1px solid rgba(15,118,110,0.06);
  min-height: 0;
}

.chat-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(135deg, #ffffff 0%, #faf8f5 100%);
  border: 1px solid rgba(15,118,110,0.06);
  border-radius: 14px;
  padding: 12px 16px;
  margin-bottom: 16px;
  box-shadow: 0 2px 8px rgba(15,118,110,0.04);
}
.chat-topbar .left { display: flex; align-items: center; gap: 12px; }
.chat-topbar .avatar { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #d1fae5, #a7f3d0); color: #0f766e; display: flex; align-items: center; justify-content: center; font-weight: 700; box-shadow: 0 2px 8px rgba(15,118,110,0.12); }
.chat-topbar .avatar-img { width: 100%; height: 100%; border-radius: 50%; object-fit: cover; display: block; }
.chat-topbar .avatar.group { background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end)); }
.chat-topbar .meta { display: flex; flex-direction: column; }
.chat-topbar .name { color: #1c1917; font-weight: 700; font-size: 15px; }
.chat-topbar .sub { color: #57534e; font-size: 12px; }
.chat-topbar .actions { display: inline-flex; align-items: center; gap: 10px; }
.chat-topbar .actions .search {
  height: 32px;
  border-radius: 9999px;
  border: 1px solid var(--border-color);
  padding: 0 12px;
  font-size: 13px;
  background: var(--color-bg);
}
.chat-topbar .actions .icon-btn { width: 32px; height: 32px; border-radius: 50%; border: none; color: #fff; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end)); cursor: pointer; }

.messages {
  position: relative;
  flex: 1;
  overflow-y: auto;
  /* Evita crecimiento infinito y asegura scroll visible */
  min-height: 0;
  margin-bottom: 12px;
  padding: 10px;
  scrollbar-width: thin;
  scrollbar-color: rgba(15, 118, 110, 0.3) transparent;
}

.messages::-webkit-scrollbar {
  width: 6px;
}

.messages::-webkit-scrollbar-track {
  background: transparent;
}

.messages::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  border-radius: 3px;
}

.messages::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
}

.messages-list { display: flex; flex-direction: column; gap: 0; }

/* Mensajes: skeleton */
.messages-skeleton { display: flex; flex-direction: column; gap: 12px; padding: 10px; }
.sk-msg { display: flex; }
.sk-msg.left { justify-content: flex-start; }
.sk-msg.right { justify-content: flex-end; }
.sk-bubble { width: 52%; max-width: 420px; height: 18px; border-radius: 16px; background: linear-gradient(90deg, #f5f0ea, #e7e0d7, #f5f0ea); animation: shimmer 1.2s infinite; }
@keyframes shimmer { 0% { background-position: -200px 0; } 100% { background-position: 200px 0; } }

/* Mensajes: empty */
.messages-empty { display: flex; align-items: center; justify-content: center; min-height: 280px; }
.empty-card { text-align: center; color: #57534e; }
.empty-hero { display: inline-flex; align-items: center; justify-content: center; color: #a8a29e; margin-bottom: 8px; }
.empty-title { font-weight: 800; color: #292524; }
.empty-sub { font-size: 12px; margin-top: 4px; }
.empty-cta {
  margin-top: 10px; padding: 8px 16px; border-radius: 10px;
  border: 1px solid rgba(15,118,110,0.15);
  background: linear-gradient(135deg, #f0fdf4, #d1fae5);
  color: #0f766e; font-weight: 700; cursor: pointer;
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.empty-cta:hover { background: linear-gradient(135deg, #d1fae5, #a7f3d0); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(15,118,110,0.15); }

/* Transiciones GPU-friendly para aparición / desaparición / reordenado */
.msg-enter-active,
.msg-leave-active { transition: transform 180ms cubic-bezier(0.22, 0.61, 0.36, 1), opacity 180ms cubic-bezier(0.22, 0.61, 0.36, 1); }
.msg-enter-from,
.msg-leave-to { opacity: 0; transform: translate3d(0, 8px, 0) scale(0.98); will-change: transform, opacity; }
.msg-move { transition: transform 180ms cubic-bezier(0.22, 0.61, 0.36, 1); will-change: transform; }
.msg-leave-active { pointer-events: none; }
.group-members-bar {
  background: linear-gradient(135deg, #faf8f5 0%, #f5f0ea 100%);
  border: 1px solid rgba(15,118,110,0.08);
  border-radius: 12px;
  padding: 10px 14px;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.members-title {
  font-weight: 700;
  color: var(--brand-gradient-start);
  font-size: 13px;
}

.members-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.member-chip {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  color: #fff;
  padding: 4px 10px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(15,118,110,0.2);
  transition: transform 0.15s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.member-chip:hover { transform: scale(1.05); }

.member-chip.empty {
  background: #e7e0d7;
  color: #292524;
}

/* Controles flotantes */
.scroll-bottom-btn {
  position: absolute;
  right: 12px;
  bottom: 180px;
  z-index: 30;
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  color: #fff;
  border: none;
  border-radius: 9999px;
  padding: 8px 16px;
  font-weight: 600;
  font-size: 13px;
  box-shadow: 0 4px 16px rgba(15,118,110,0.3);
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.scroll-bottom-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 22px rgba(15,118,110,0.4);
}

.new-messages-banner {
  position: absolute;
  left: 50%;
  bottom: 236px;
  transform: translateX(-50%);
  z-index: 25;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  color: #fff;
  border: none;
  border-radius: 9999px;
  padding: 7px 16px;
  font-size: 12px;
  font-weight: 700;
  box-shadow: 0 4px 16px rgba(15,118,110,0.3);
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.chat-window {
  position: relative;
}

/* Composer fijo con blur y sombra */
.composer-bar {
  position: sticky;
  bottom: 0;
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(12px);
  border-top: 1px solid rgba(15,118,110,0.06);
  border-radius: 12px;
  padding: 8px;
  box-shadow: 0 -2px 12px rgba(0,0,0,0.03);
}

.chat-window {
  padding: 18px;
  border-radius: 28px;
  background: linear-gradient(180deg, rgba(255,255,255,0.95) 0%, rgba(248,243,236,0.92) 100%);
  border: 1px solid rgba(120, 104, 85, 0.1);
  box-shadow: 0 18px 42px rgba(28, 18, 10, 0.06);
}

.chat-topbar {
  gap: 14px;
  padding: 12px 14px;
  border-radius: 18px;
  background: rgba(255,255,255,0.78);
  border: 1px solid rgba(120, 104, 85, 0.08);
  box-shadow: none;
}

.chat-context {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.chat-avatar {
  width: 42px;
  height: 42px;
  border-radius: 15px;
  background: linear-gradient(135deg, #d1fae5, #a7f3d0);
  color: #0f766e;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  box-shadow: 0 8px 18px rgba(15,118,110,0.14);
  flex-shrink: 0;
  overflow: hidden;
}

.chat-avatar.group {
  background: linear-gradient(135deg, #0f766e, #d97706);
  color: #fff;
}

.chat-meta {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.chat-name {
  color: #1c1917;
  font-weight: 800;
  font-size: 15px;
  letter-spacing: -0.02em;
}

.chat-sub {
  color: #6b6258;
  font-size: 12px;
  font-weight: 600;
}

.chat-tools {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.chat-search {
  width: 220px;
  max-width: 100%;
  height: 36px;
  border-radius: 999px;
  border: 1px solid rgba(120, 104, 85, 0.14);
  padding: 0 14px;
  font-size: 13px;
  background: rgba(255,255,255,0.96);
  color: #1f1a16;
}

.chat-search:focus {
  outline: none;
  border-color: rgba(15, 118, 110, 0.3);
  box-shadow: 0 0 0 4px rgba(15, 118, 110, 0.08);
}

.group-members-bar {
  gap: 10px;
  padding: 8px 12px;
  margin-top: 10px;
  margin-bottom: 10px;
  border-radius: 14px;
  background: rgba(245, 240, 234, 0.9);
  border: 1px solid rgba(120, 104, 85, 0.08);
}

.members-title {
  color: #0f766e;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.member-chip {
  padding: 4px 9px;
  border-radius: 999px;
  background: rgba(15,118,110,0.08);
  color: #115e59;
  box-shadow: none;
}

.member-chip:hover {
  transform: none;
}

.member-chip.empty {
  background: rgba(120, 104, 85, 0.12);
  color: #574b41;
}

.messages {
  margin-bottom: 10px;
  padding: 10px 8px;
}

.messages-empty {
  min-height: 240px;
}

.empty-card {
  max-width: 320px;
}

.empty-title {
  font-size: 16px;
}

.empty-sub {
  font-size: 13px;
  color: #6b6258;
}

.empty-hero {
  color: #9a8f84;
}

.empty-cta {
  background: rgba(15,118,110,0.08);
  color: #0f766e;
  border-color: rgba(15,118,110,0.12);
  box-shadow: none;
}

.empty-cta:hover {
  background: rgba(15,118,110,0.12);
  box-shadow: none;
}

.scroll-bottom-btn {
  right: 10px;
  bottom: 154px;
  padding: 8px 14px;
  background: linear-gradient(135deg, #0f766e, #d97706);
  box-shadow: 0 10px 22px rgba(15,118,110,0.24);
}

.new-messages-banner {
  bottom: 212px;
  background: linear-gradient(135deg, #0f766e, #d97706);
}

.composer-bar {
  margin-top: 10px;
  padding: 10px;
  border-radius: 18px;
  background: rgba(255,255,255,0.9);
  border: 1px solid rgba(120, 104, 85, 0.1);
  backdrop-filter: blur(10px);
  box-shadow: 0 -2px 12px rgba(28,18,10,0.03);
}

@media (max-width: 768px) {
  .chat-window {
    padding: 14px;
    border-radius: 22px;
  }

  .chat-topbar {
    flex-direction: column;
    align-items: stretch;
  }

  .chat-tools {
    width: 100%;
  }

  .chat-search {
    width: 100%;
  }

  .scroll-bottom-btn {
    bottom: 170px;
  }

  .new-messages-banner {
    bottom: 228px;
  }
}

</style>
