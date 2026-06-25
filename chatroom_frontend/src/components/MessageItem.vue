<template>
  <div :class="['message-row', isMine ? 'mine' : '', continuation ? 'continuation' : '']">
    <div
      class="avatar"
      :class="isMine ? 'mine' : ''"
      :title="senderName"
      role="img"
      :aria-label="'Avatar of ' + (senderName || 'user')"
    >
      <img v-if="senderAvatarUrl" :src="senderAvatarUrl" alt="avatar" class="avatar-img" />
      <span v-else>{{ senderInitial }}</span>
    </div>
    <div :class="['message-item', isMine ? 'mine' : '']">
      <span class="sender">{{ typeof message.sender === 'object' && message.sender ? message.sender.username : message.sender }}:</span>
      <div class="content">
        <template v-if="message.type === 'image' && message.fileUrl">
          <a :href="message.fileUrl" target="_blank" rel="noopener noreferrer">
            <img
              :src="message.fileUrl"
              :srcset="message.fileUrl + ' 1x, ' + message.fileUrl + ' 2x'"
              alt="attached image"
              class="attachment-image"
              :class="imageLoaded ? '' : 'image-loading'"
              loading="lazy"
              decoding="async"
              @load="imageLoaded = true"
            />
          </a>
          <div v-if="message.content" class="caption">{{ message.content }}</div>
        </template>
        <template v-else-if="message.type === 'file' && message.fileUrl">
          <a :href="message.fileUrl" target="_blank" rel="noopener noreferrer" class="attachment-file">
            <Icon name="paperclip" :size="18" />
            <span class="file-label">{{ message.content || 'File' }}</span>
          </a>
        </template>
        <template v-else>
          <span v-html="highlightedContent"></span>
        </template>
      </div>
      <span class="timestamp">
        {{ formattedTime }}
        <span v-if="isMine && deliveryStatus" class="status-icon" :title="deliveryStatus.label">{{ deliveryStatus.icon }}</span>
      </span>
    </div>
  </div>
</template>

<script>
import Icon from './Icon.vue'
export default {
  name: 'MessageItem',
  components: { Icon },
  props: {
    message: {
      type: Object,
      required: true
    },
    currentUserId: {
      type: [String, Number],
      required: true
    },
    continuation: { type: Boolean, default: false },
    highlightQuery: { type: String, default: '' }
  },
  data() {
    return { imageLoaded: false }
  },
  computed: {
    isMine() {
      if (typeof this.message.sender === 'object' && this.message.sender) {
        return this.message.sender.id == this.currentUserId;
      }
      return this.message.sender == this.currentUserId;
    },
    senderName() {
      const s = this.message && this.message.sender
      if (!s) return ''
      if (typeof s === 'object') return s.username || s.name || ''
      return String(s)
    },
    senderAvatarUrl() {
      const s = this.message && this.message.sender
      if (s && typeof s === 'object' && s.avatarUrl) {
        return s.avatarUrl
      }
      if (this.isMine && this.$store && this.$store.getters) {
        const cu = this.$store.getters['auth/currentUser']
        return (cu && cu.avatarUrl) || ''
      }
      return ''
    },
    senderInitial() {
      const n = this.senderName || ''
      return n ? n.charAt(0).toUpperCase() : '?'
    },
    formattedTime() {
      if (!this.message.timestamp) return '';
      const date = new Date(this.message.timestamp);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    },
    deliveryStatus() {
      const s = (this.message && this.message.status) || ''
      // soporta estados: 'sent' | 'delivered' | 'read'
      if (s === 'read') return { icon: '✔✔', label: 'Seen' }
      if (s === 'delivered') return { icon: '✔✔', label: 'Delivered' }
      if (s === 'sent') return { icon: '✔', label: 'Sent' }
      return null
    },
    highlightedContent() {
      const content = (this.message && this.message.content) || ''
      const q = (this.highlightQuery || '').trim()
      if (!q) return this.escapeHtml(content)
      try {
        const re = new RegExp(this.escapeRegExp(q), 'gi')
        const escaped = this.escapeHtml(content)
        return escaped.replace(re, (m) => `<mark class="highlight">${m}</mark>`)
      } catch (e) {
        return this.escapeHtml(content)
      }
    }
  },
  methods: {
    escapeHtml(str) {
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
    },
    escapeRegExp(str) {
      return String(str).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    }
  }
}
</script>

<style scoped>
.message-row {
  display: flex;
  align-items: flex-end;
  gap: var(--space-2);
  margin-bottom: var(--space-2);
  padding: 0 var(--space-2);
}

.message-row.mine {
  flex-direction: row-reverse;
  justify-content: flex-start;
}

.avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: linear-gradient(135deg, #d1fae5, #a7f3d0);
  color: #0f766e;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  box-shadow: 0 2px 8px rgba(15,118,110,0.12);
  flex-shrink: 0;
  overflow: hidden;
  transition: transform 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.avatar:hover {
  transform: scale(1.1);
}

.avatar.mine {
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  color: #fff;
  box-shadow: 0 2px 8px rgba(15,118,110,0.25);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.message-item {
  position: relative;
  padding: 10px 14px;
  border-radius: 18px;
  max-width: min(75%, 600px);
  display: flex;
  flex-direction: column;
  word-wrap: break-word;
  animation: messageSlideIn 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
  border: 1px solid transparent;
}

.message-item:hover {
  box-shadow: 0 4px 14px rgba(0,0,0,0.08);
  transform: translateY(-1px);
}

@keyframes messageSlideIn {
  from { opacity: 0; transform: translateY(10px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.message-item.mine {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  color: #fff;
  border-bottom-right-radius: 4px;
  margin-right: 4px;
  box-shadow: 0 2px 12px rgba(15,118,110,0.2);
}

.message-item.mine:hover {
  box-shadow: 0 4px 18px rgba(15,118,110,0.3);
}

.message-item:not(.mine) {
  background: var(--color-surface);
  color: var(--text-primary);
  border-color: rgba(231,224,215,0.8);
  border-bottom-left-radius: 4px;
  margin-left: 4px;
}

.sender {
  font-size: 11px;
  font-weight: 700;
  margin-bottom: 3px;
  color: var(--brand-gradient-start);
  opacity: 0.85;
  margin-left: 2px;
  letter-spacing: 0.2px;
}
.message-item.mine .sender { display: none; }

.content {
  line-height: 1.55;
  font-size: var(--font-size-md);
  position: relative;
  z-index: 1;
}

/* Timestamp */
.timestamp {
  align-self: flex-end;
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  margin-top: 4px;
  opacity: 0.65;
  user-select: none;
  line-height: 1;
  transition: opacity 0.2s;
}

.message-item:hover .timestamp {
  opacity: 0.85;
}

.message-item.mine .timestamp {
  color: rgba(255, 255, 255, 0.75);
}

.message-item:not(.mine) .timestamp {
  color: var(--text-muted);
}

.status-icon {
  font-size: 12px;
}

/* Images & Files */
.attachment-image {
  max-width: 100%;
  max-height: 300px;
  border-radius: 12px;
  display: block;
  cursor: zoom-in;
  margin-bottom: 4px;
  transition: transform 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.attachment-image:hover {
  transform: scale(1.02);
}

.attachment-file {
  background: rgba(0,0,0,0.04);
  padding: 10px 14px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  color: inherit;
  font-weight: 500;
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
  border: 1px solid rgba(0,0,0,0.04);
}
.message-item.mine .attachment-file {
  background: rgba(255,255,255,0.15);
  color: #fff;
  border-color: rgba(255,255,255,0.1);
}
.attachment-file:hover {
  background: rgba(0,0,0,0.08);
  transform: translateY(-1px);
}
.message-item.mine .attachment-file:hover {
  background: rgba(255,255,255,0.25);
}

/* Continuation Logic */
.message-row.continuation {
  margin-top: -4px;
  margin-bottom: var(--space-2);
}
.message-row.continuation .avatar {
  visibility: hidden;
  height: 0;
}

.message-row.continuation .message-item {
  border-radius: 18px;
  margin-top: 2px;
}
.message-row.continuation .message-item.mine {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 4px;
}
.message-row.continuation .message-item:not(.mine) {
  border-top-left-radius: 4px;
  border-bottom-left-radius: 4px;
}

/* Highlight */
.highlight {
  background: #fef08a;
  color: #000;
  padding: 1px 3px;
  border-radius: 3px;
  box-shadow: 0 0 0 1px rgba(250,204,21,0.3);
}

/* Mobile */
@media (max-width: 768px) {
  .message-item {
    max-width: 85%;
    font-size: 15px;
  }
  .avatar {
    width: 28px;
    height: 28px;
    font-size: 12px;
  }
  .actions {
    display: none !important;
  }
}

.message-row {
  gap: 10px;
  margin-bottom: 10px;
  align-items: flex-end;
}

.avatar {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  border: 1px solid rgba(126, 107, 90, 0.16);
  box-shadow: 0 10px 24px rgba(87, 61, 43, 0.08);
}

.message-item {
  padding: 12px 14px 10px;
  border-radius: 18px;
  max-width: min(72%, 620px);
  box-shadow: 0 14px 28px rgba(74, 54, 39, 0.08);
}

.message-item:hover {
  box-shadow: 0 18px 34px rgba(74, 54, 39, 0.1);
  transform: translateY(-1px);
}

.message-item.mine {
  background: linear-gradient(145deg, #0f766e 0%, #115e59 100%);
  box-shadow: 0 16px 32px rgba(15, 118, 110, 0.2);
}

.message-item.mine:hover {
  box-shadow: 0 18px 38px rgba(15, 118, 110, 0.24);
}

.message-item:not(.mine) {
  background:
    linear-gradient(180deg, rgba(255, 252, 247, 0.98) 0%, rgba(248, 243, 235, 0.96) 100%);
  border-color: rgba(214, 201, 186, 0.9);
}

.sender {
  margin-bottom: 5px;
  color: #8b5e3c;
}

.content {
  line-height: 1.6;
}

.caption {
  margin-top: 8px;
  font-size: 13px;
  line-height: 1.45;
  opacity: 0.9;
}

.timestamp {
  margin-top: 6px;
  font-size: 11px;
  opacity: 0.58;
}

.message-item:hover .timestamp {
  opacity: 0.76;
}

.attachment-image {
  border-radius: 14px;
  margin-bottom: 2px;
  box-shadow: 0 14px 28px rgba(56, 41, 30, 0.12);
}

.attachment-file {
  padding: 11px 13px;
  gap: 9px;
  border-radius: 12px;
  border-color: rgba(167, 145, 122, 0.18);
  background: rgba(123, 97, 67, 0.06);
}

.message-item.mine .attachment-file {
  background: rgba(255, 255, 255, 0.14);
  border-color: rgba(255, 255, 255, 0.12);
}

.file-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.message-row.continuation {
  margin-top: -2px;
  margin-bottom: 8px;
}

.message-row.continuation .message-item {
  margin-top: 0;
}

@media (max-width: 768px) {
  .message-row {
    gap: 8px;
    margin-bottom: 8px;
  }

  .avatar {
    width: 30px;
    height: 30px;
    flex-basis: 30px;
  }

  .message-item {
    max-width: 88%;
    padding: 11px 12px 9px;
  }
}
</style>
