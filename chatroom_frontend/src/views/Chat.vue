<template>
  <div class="chat-page">
    <AppDock />
    <section class="chat-shell">
      <div v-if="toast" class="toast" :class="toastClass()">{{ toast.message }}</div>
      <header class="chat-page-header">
        <div class="chat-page-title-wrap">
          <p class="chat-page-kicker">ConnectHub</p>
          <h1 class="chat-page-title">Messages</h1>
          <p class="chat-page-subtitle">Unread first. Noise last.</p>
        </div>
      </header>
      <div class="chat-workbench">
        <aside class="conversation-rail">
          <div class="rail-header">
            <div class="rail-title-row">
              <div>
                <div class="rail-title">Conversations</div>
                <div class="rail-subtitle">Jump fast. Stay focused.</div>
              </div>
            </div>
            <nav class="chats-tabs" role="tablist" aria-label="Chat list">
              <button :class="['tab', activeTab === 'all' && 'active']" role="tab" aria-selected="activeTab==='all'" @click="activeTab='all'">All</button>
              <button :class="['tab', activeTab === 'contacts' && 'active']" role="tab" aria-selected="activeTab==='contacts'" @click="activeTab='contacts'">Contacts</button>
              <button :class="['tab', activeTab === 'groups' && 'active']" role="tab" aria-selected="activeTab==='groups'" @click="activeTab='groups'">Groups</button>
            </nav>
          </div>
          <div class="rail-body">
            <template v-if="activeTab==='all'">
              <UserList :users="sortedUsers" :loading="loadingUsers" :unreadCounts="unreadCounts" :selectedUser="selectedUser" :onlineUsers="onlineUsers" :lastMessageMap="lastMessageMap" @select="selectUser" @refresh="refreshUsers" />
              <div class="divider"></div>
              <GroupList :groups="groups" :loading="loadingGroups" :groupUnreadCounts="groupUnreadCounts" :selectedGroup="selectedGroup" @select="selectGroup" @refresh="refreshGroups" />
            </template>
            <template v-else-if="activeTab==='contacts'">
              <UserList :users="sortedUsers" :loading="loadingUsers" :unreadCounts="unreadCounts" :selectedUser="selectedUser" :onlineUsers="onlineUsers" :lastMessageMap="lastMessageMap" @select="selectUser" @refresh="refreshUsers" />
            </template>
            <template v-else>
              <GroupList :groups="groups" :loading="loadingGroups" :groupUnreadCounts="groupUnreadCounts" :selectedGroup="selectedGroup" @select="selectGroup" @refresh="refreshGroups" />
            </template>
          </div>
        </aside>
        <main class="message-stage">
          <template v-if="currentUser && (selectedUser || selectedGroup)">
            <ChatWindow 
              ref="chatWindow"
              :messages="filteredMessages" 
              :chatUser="selectedUser" 
              :chatGroup="selectedGroup"
              :chatType="chatType"
              :currentUserId="currentUser.id"
              :searchQuery="searchQuery"
              :loading="loadingMessages"
              @update:searchQuery="searchQuery = $event"
              @search="searchQuery = $event"
              @compose="focusComposer">
              <div class="chat-input-area">
                <div class="chat-input-actions gap8-2">
                  <button class="icon-btn" type="button" title="Emoji" aria-label="Emoji" @click="toggleEmojiPicker">
                    <Icon name="smile" :size="18" />
                  </button>
                  <button class="icon-btn" type="button" title="Attach" aria-label="Attach" @click="triggerAttach">
                    <Icon name="paperclip" :size="18" />
                  </button>
                  <input ref="fileInput" type="file" style="display:none" @change="handleFileSelected" />
                </div>
                <input ref="composerInput" v-model="inputMsg" @keyup.enter="send" placeholder="Type a message..." />
                <button @click="send" class="send-btn" aria-label="Send">
                  <Icon name="send" :size="18" />
                  <span class="send-label">Send</span>
                </button>
              </div>
              <div v-if="showEmojiPicker" class="emoji-picker">
                <button v-for="e in emojis" :key="e" class="emoji-btn" @click="insertEmoji(e)" type="button">{{ e }}</button>
              </div>
            </ChatWindow>
          </template>
          <template v-else>
            <div class="empty-chat" aria-live="polite">
              <div class="empty-chat-panel" role="region" aria-label="Select a chat">
                <div class="empty-chat-mark" aria-hidden="true">
                  <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M4 5.5A3.5 3.5 0 0 1 7.5 2h9A3.5 3.5 0 0 1 20 5.5v7A3.5 3.5 0 0 1 16.5 16H13l-3.5 3.5c-.6.6-1.5.18-1.5-.7V16H7.5A3.5 3.5 0 0 1 4 12.5v-7Z" fill="currentColor"/>
                  </svg>
                </div>
                <div class="empty-chat-title">Pick a chat</div>
                <div class="empty-chat-text">Unread is waiting on the left.</div>
              </div>
            </div>
          </template>
        </main>
      </div>
    </section>
  </div>
</template>

<script>
import UserList from '../components/UserList.vue'
import GroupList from '../components/GroupList.vue'
import ChatWindow from '../components/ChatWindow.vue'
import AppDock from '../components/AppDock.vue'
import Icon from '../components/Icon.vue'
import { mapGetters } from 'vuex'
import { 
  disconnectWebSocket, 
  setOnlineUsersCallback, 
  sendMessage, 
  subscribe, 
  connectWebSocket 
} from '../services/websocket.js'

export default {
  name: 'ChatPage',
  components: { AppDock, UserList, GroupList, ChatWindow, Icon },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    userInitials() {
      const name = (this.currentUser && this.currentUser.username) || ''
      const parts = name.trim().split(/\s+/).filter(Boolean)
      const initials = parts.slice(0, 2).map(p => (p[0] || '').toUpperCase()).join('')
      return initials || 'U'
    },
    sortedUsers() {
      if (!this.currentUser) return this.users;
      // Filtrar superadmins de la lista
      const others = this.users.filter(u => u.id !== this.currentUser.id && u.role !== 'SUPER_ADMIN');
      return [this.currentUser, ...others];
    },
    filteredMessages() {
      const list = Array.isArray(this.messages) ? this.messages : []
      const q = (this.searchQuery || '').trim().toLowerCase()
      if (!q) return list
      const includesQ = (text) => String(text || '').toLowerCase().includes(q)
      return list.filter(m => {
        const contentMatch = includesQ(m.content)
        const sender = m && m.sender
        const senderName = typeof sender === 'object' ? (sender.username || sender.name) : sender
        const authorMatch = includesQ(senderName)
        return contentMatch || authorMatch
      })
    }
  },
  data() {
    return {
      toast: null,
      toastTimer: null,
      searchQuery: '',
      users: [],
      groups: [],
      messages: [],
      inputMsg: '',
      selectedUser: null,
      selectedGroup: null, // Grupo seleccionado
      chatType: 'user', // 'user' o 'group'
      globalSubscription: null,
      groupSubscriptions: {}, // Suscripciones a grupos
      wsConnected: false,
      unreadCounts: {}, // 存储每个用户的未读消息数量
      groupUnreadCounts: {}, // 存储每个群组的未读消息数量
      onlineUsers: [], // 存储在线用户列表
      audioContext: null, // AudioContext para sonidos de notificación
      userHasInteracted: false, // Flag para saber si el usuario ha interactuado
      showEmojiPicker: false,
      emojis: ['😀','😁','😂','😊','😍','😎','😘','😅','😉','🤩','🥳','😇','🙌','👍','👏','🔥','✨','❤️','💯','🎉'],
      activeTab: 'all',
      lastMessageMap: {},
      loadingUsers: false,
      loadingGroups: false,
      loadingMessages: false
    }
  },
  methods: {
    showToast(message, type = 'success') {
      clearTimeout(this.toastTimer)
      this.toast = { message, type }
      this.toastTimer = setTimeout(() => { this.toast = null }, 2600)
    },
    toastClass() {
      const t = (this.toast && this.toast.type) || 'success'
      return {
        'toast-success': t === 'success',
        'toast-error': t === 'error',
        'toast-info': t === 'info'
      }
    },
    normalizeOnlineUsers(list) {
      if (!Array.isArray(list)) return []
      return list.map(u => {
        const id = (u && (u.id ?? u.userId))
        const username = (u && (u.username ?? u.name ?? u.userName))
        return { id, username }
      }).filter(u => u.id !== undefined && u.username)
    },
    async selectUser(user) {
      try {
        this.selectedUser = user
        this.selectedGroup = null
        this.chatType = 'user'
        this.loadingMessages = true
        
        const { fetchMessages, markMessagesAsRead } = await import('../services/chat.service.js')
        const res = await fetchMessages({ receiverId: user.id, userId: this.currentUser && this.currentUser.id })
        const sorted = res.data.slice().sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))
        this.messages = sorted
        const last = sorted[sorted.length - 1]
        if (last) {
          const isMine = last.sender && last.sender.id === this.currentUser.id
          const senderName = last.sender ? (last.sender.username || last.sender.name) : ''
          this.lastMessageMap[user.id] = { content: last.content, timestamp: last.timestamp, isMine, senderName }
        }
        
        // 标记消息为已读
          if (this.currentUser) {
            await markMessagesAsRead(this.currentUser.id, user.id)
            // Limpiar contador de mensajes no leídos de este usuario
            this.unreadCounts[user.id] = 0
            console.log(`Limpiar contador de no leídos del usuario ${user.id}`)
          }
      } catch (e) {
        console.error('Error en selectUser:', e)
      } finally {
        this.loadingMessages = false
        this.scrollToBottom()
      }
    },
    handleNewMessage(message) {
      // Resolver senderId, compatible con diferentes estructuras
      const senderId = (message && message.sender && (message.sender.id ?? message.sender.userId)) || message.senderId
      const isFromSelf = senderId && this.currentUser && senderId === this.currentUser.id
      
      console.log('Procesando mensaje nuevo:', {
        senderId,
        isFromSelf,
        isGroup: !!message.group,
        selectedUserId: this.selectedUser?.id,
        chatType: this.chatType
      })
      
      // Si el mensaje no es del usuario actual
      if (!isFromSelf) {
        
        // Solo procesar mensajes individuales para conteo de no leídos
        // Los mensajes de grupo no deben aparecer como no leídos en usuarios individuales
        if (!message.group && senderId) {
          // Incrementar contador solo si no es el chat actualmente seleccionado
          const isCurrentChat = this.chatType === 'user' && this.selectedUser && senderId === this.selectedUser.id
          
          if (!isCurrentChat) {
             const newCount = (this.unreadCounts[senderId] || 0) + 1
             // En Vue 3, usar asignación directa para reactividad
             this.unreadCounts[senderId] = newCount
             console.log(`Usuario ${senderId} mensajes no leídos actualizados a:`, newCount)
           }
          // Actualizar último mensaje del remitente
          this.lastMessageMap[senderId] = { 
            content: message.content, 
            timestamp: message.timestamp, 
            isMine: isFromSelf,
            senderName: message.sender ? (message.sender.username || message.sender.name) : ''
          }
        }
        
        // Mostrar notificación de escritorio solo para mensajes individuales
        if (!message.group) {
          this.showNotification(message)
        }
        
        // Reproducir sonido de notificación
        this.playNotificationSound()
      }
    },
    
    showNotification(message) {
      if ('Notification' in window && Notification.permission === 'granted') {
        let title = `New message from ${message.sender.username}`
        if (message.group) {
          title = `${message.sender.username} in ${message.group.name}`
        }
        new Notification(title, {
          body: message.content,
          icon: '/favicon.ico',
          tag: 'chat-message'
        })
      } else if ('Notification' in window && Notification.permission !== 'denied') {
        Notification.requestPermission().then(permission => {
          if (permission === 'granted') {
            this.showNotification(message)
          }
        })
      }
    },
    playNotificationSound() {
      // Solo reproducir sonido si el usuario ha interactuado con la página
      if (!this.userHasInteracted) {
        console.log('No se puede reproducir sonido: el usuario no ha interactuado con la página')
        return
      }

      try {
        // Crear o reutilizar AudioContext
        if (!this.audioContext) {
          this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
        }

        // Reanudar AudioContext si está suspendido
        if (this.audioContext.state === 'suspended') {
          this.audioContext.resume().then(() => {
            this.createNotificationSound()
          }).catch(error => {
            console.error('Error al reanudar AudioContext:', error)
          })
        } else {
          this.createNotificationSound()
        }
      } catch (error) {
        console.error('Error al crear AudioContext:', error)
      }
    },
    
    createNotificationSound() {
      if (!this.audioContext) return

      try {
        const oscillator = this.audioContext.createOscillator()
        const gainNode = this.audioContext.createGain()
        
        oscillator.connect(gainNode)
        gainNode.connect(this.audioContext.destination)
        
        oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime)
        oscillator.frequency.setValueAtTime(600, this.audioContext.currentTime + 0.1)
        
        gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2)
        
        oscillator.start(this.audioContext.currentTime)
        oscillator.stop(this.audioContext.currentTime + 0.2)
      } catch (error) {
        console.error('Error al crear sonido de notificación:', error)
      }
    },
    async selectGroup(group) {
      try {
        this.selectedGroup = group
        this.selectedUser = null // Limpiar selección de usuario
        this.chatType = 'group'
        this.loadingMessages = true
        
        const { fetchMessages, markGroupMessagesAsRead } = await import('../services/chat.service.js')
        const meId = this.currentUser && this.currentUser.id
        const res = await fetchMessages({ groupId: group.id, userId: meId })
        this.messages = res.data.slice().sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))
        
        // Suscribirse a mensajes del grupo
        this.subscribeToGroupChannel(group.id)
        
        // Marcar como leído y limpiar contador
        if (group && group.id && meId) {
          try {
            await markGroupMessagesAsRead(meId, group.id)
            this.groupUnreadCounts[group.id] = 0
          } catch (e) {
            console.error('Error al marcar grupo como leído:', e)
          }
        }
      } catch (e) {
        console.error('Error en selectGroup:', e)
      } finally {
        this.loadingMessages = false
        this.scrollToBottom()
      }
    },
    async send() {
      if (this.inputMsg.trim()) {
        const content = this.inputMsg
        // Comprobar estado de conexión antes de enviar
        try {
          const { isConnected } = await import('../services/websocket.js')
          if (!isConnected || !isConnected()) {
            this.showToast('Connection lost. Could not send', 'error')
            return
          }
        } catch (e) {
          // Si falla la detección, continuar pero avisar
          this.showToast('Sending…', 'info')
        }

        if (this.chatType === 'user' && this.selectedUser) {
          const message = {
            sender: { id: this.currentUser.id, username: this.currentUser.username, avatarUrl: this.currentUser.avatarUrl },
            receiver: { id: this.selectedUser.id, username: this.selectedUser.username },
            content,
            type: 'text',
            timestamp: new Date().toISOString()
          }
          // Enviar via STOMP; la UI se actualiza solo cuando el servidor hace eco
          sendMessage('/app/chat/single', message)
          this.showToast('Message sent', 'success')
          // Actualizar hint de último mensaje en la lista
          this.lastMessageMap[this.selectedUser.id] = { 
            content, 
            timestamp: message.timestamp,
            isMine: true,
            senderName: this.currentUser.username
          }
        } else if (this.chatType === 'group' && this.selectedGroup) {
          const message = {
            sender: { id: this.currentUser.id, username: this.currentUser.username, avatarUrl: this.currentUser.avatarUrl },
            group: { id: this.selectedGroup.id, name: this.selectedGroup.name },
            content,
            type: 'text',
            timestamp: new Date().toISOString()
          }
          // Enviar via STOMP; no hacer inserción optimista
          sendMessage('/app/chat/group', message)
          this.showToast('Sent to group', 'success')
        }
        this.inputMsg = ''
      }
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker
    },
    insertEmoji(e) {
      this.inputMsg = (this.inputMsg || '') + e
    },
    triggerAttach() {
      const el = this.$refs.fileInput
      if (el) el.click()
    },
    async handleFileSelected(evt) {
      try {
        const file = evt.target.files && evt.target.files[0]
        if (!file) return
        const { uploadAttachment } = await import('../services/chat.service.js')
        const res = await uploadAttachment(file)
        const { url, type } = res.data || {}
        if (!url || !type) return
        const baseMessage = {
          sender: { id: this.currentUser.id, username: this.currentUser.username, avatarUrl: this.currentUser.avatarUrl },
          content: file.name,
          type,
          fileUrl: url,
          timestamp: new Date().toISOString()
        }
        if (this.chatType === 'user' && this.selectedUser) {
          const message = { ...baseMessage, receiver: { id: this.selectedUser.id, username: this.selectedUser.username } }
          // Enviar via STOMP; la UI se actualizará con el eco del servidor
          sendMessage('/app/chat/single', message)
        } else if (this.chatType === 'group' && this.selectedGroup) {
          const message = { ...baseMessage, group: { id: this.selectedGroup.id, name: this.selectedGroup.name } }
          sendMessage('/app/chat/group', message)
        }
        // limpiar input de archivo
        evt.target.value = ''
      } catch (err) {
        console.error('Error al enviar adjunto:', err)
        this.showToast('Failed to send attachment', 'error')
      }
    },
    subscribeToGroupChannel(groupId) {
      const topic = `/topic/group/${groupId}`
      console.log('Suscribiendo a canal de grupo:', topic)
      
      // Desuscribirse del canal anterior si existe
      if (this.groupSubscriptions[groupId]) {
        this.groupSubscriptions[groupId].unsubscribe()
      }
      
      this.groupSubscriptions[groupId] = subscribe(topic, (msg) => {
        console.log('Mensaje de grupo recibido:', msg)
        const msgGroupId = (msg && msg.group && msg.group.id) || groupId
        const isCurrentGroup = this.chatType === 'group' && this.selectedGroup && msg.group && msg.group.id === this.selectedGroup.id
        
        if (isCurrentGroup) {
          this.messages.push(msg)
          // Scroll to bottom after adding message
          this.$nextTick(() => {
            this.scrollToBottom()
          })
        } else {
          // Verificar si el mensaje es propio para no notificar
          const senderId = (msg && msg.sender && (msg.sender.id ?? msg.sender.userId)) || msg.senderId
          const isFromSelf = senderId && this.currentUser && senderId === this.currentUser.id

          if (!isFromSelf) {
            // Incrementar contador de no leídos para el grupo
            const newCount = (this.groupUnreadCounts[msgGroupId] || 0) + 1
            this.groupUnreadCounts[msgGroupId] = newCount
            console.log(`Grupo ${msgGroupId} mensajes no leídos:`, newCount)
            
            // Reproducir sonido de notificación para mensajes de grupo no visibles
            this.playNotificationSound()
            // Mostrar notificación de escritorio
            this.showNotification(msg)
          }
        }
      })
    },
    
    subscribeToAllGroupChannels() {
      if (!Array.isArray(this.groups)) return
      for (const g of this.groups) {
        if (g && g.id) {
          this.subscribeToGroupChannel(g.id)
        }
      }
    },
    
    initWebSocketConnection() {
      if (!this.currentUser) {
        console.error('No hay información de usuario actual, no se puede establecer conexión WebSocket')
        return
      }
     
      connectWebSocket(window.location.origin + '/ws', this.currentUser.username, null, () => {
        console.log('WebSocket conectado')
        this.wsConnected = true
        
        // Configurar callback de usuarios en línea
        setOnlineUsersCallback((onlineUsers) => {
          const normalized = this.normalizeOnlineUsers(onlineUsers)
          this.onlineUsers = normalized
          console.log('Lista de usuarios en línea actualizada (normalizada):', normalized)
        })
        
        // Tras conectar WebSocket, suscribirse al canal del usuario actual
        setTimeout(() => {
          this.subscribeToPublicChannel()
          this.subscribeToGlobalUserChannel()
          this.subscribeToControlChannel()
          // Suscribirse a todos los canales de grupo para contar no leídos
          this.subscribeToAllGroupChannels()
        }, 100) // Pequeño retraso para asegurar que la conexión esté lista
      }, (error) => {
        console.error('Error de conexión WebSocket:', error)
        this.wsConnected = false
      })
    },
    
    subscribeToPublicChannel() {
      // Canal público para eventos generales como actualizaciones de perfil
      subscribe('/topic/public', (msg) => {
        if (msg && msg.action === 'user_updated') {
          // Si es el usuario actual, actualizar vuex
          if (String(msg.userId) === String(this.currentUser.id)) {
            this.$store.commit('auth/SET_USER', { ...this.currentUser, avatarUrl: msg.avatarUrl, username: msg.username })
          }
          
          // Actualizar lista de usuarios local
          this.users = this.users.map(u => {
            if (String(u.id) === String(msg.userId)) {
              return { ...u, avatarUrl: msg.avatarUrl, username: msg.username }
            }
            return u
          })
          
          // Si el usuario actualizado es el seleccionado, actualizarlo también
          if (this.selectedUser && String(this.selectedUser.id) === String(msg.userId)) {
             this.selectedUser = { ...this.selectedUser, avatarUrl: msg.avatarUrl, username: msg.username }
          }
        }
      })
    },

    subscribeToGlobalUserChannel() {
      if (this.currentUser) {
        const topic = `/user/queue/messages`
        console.log('Suscripción al canal de mensajes:', topic)
        this.globalSubscription = subscribe(topic, (msg) => {
          console.log('Nuevo mensaje recibido:', msg)
          // Procesar métricas/contador, notificaciones, etc.
          this.handleNewMessage(msg)

          // Añadir al hilo si pertenece al chat usuario actual,
          // ya sea como remitente o como receptor.
          const senderId = (msg && msg.sender && (msg.sender.id ?? msg.sender.userId)) || msg.senderId
          const receiverId = (msg && msg.receiver && (msg.receiver.id ?? msg.receiver.userId)) || msg.receiverId
          const isUserChat = this.chatType === 'user' && !!this.selectedUser
          const belongsToCurrentChat = isUserChat && (senderId === this.selectedUser.id || receiverId === this.selectedUser.id)

          if (belongsToCurrentChat) {
            this.messages.push(msg)
            this.$nextTick(() => {
              this.scrollToBottom()
            })
          }
        })
        
        if (this.globalSubscription) {
          console.log('Suscripción global exitosa')
        } else {
          console.error('Suscripción global fallida')
        }
      } else {
        console.error('No hay usuario actual, no se pueden suscribir mensajes')
      }
    },

    // Suscribirse al canal de control para recibir eventos como force-logout
    subscribeToControlChannel() {
      if (this.currentUser) {
        const topic = `/user/queue/control`
        console.log('Suscripción al canal de control:', topic)
        this.controlSubscription = subscribe(topic, (msg) => {
          try {
            if (msg && msg.action === 'force_logout') {
              console.warn('Recibido force_logout; desconectando WebSocket')
              // Desconectar socket y notificar al usuario
              disconnectWebSocket()
              this.wsConnected = false
              const reason = msg && (msg.reason || msg.detail || msg.message)
              let text = 'You were disconnected by an admin.'
              if (reason === 'password_changed') {
                text = 'Your password was updated by an admin. Please sign in again.'
              } else if (reason === 'account_disabled') {
                text = 'Your account was disabled by an admin.'
              }
              alert(text)
              // Cerrar sesión y redirigir al login
              try {
                this.$store.dispatch('auth/logout')
              } catch (e) {
                console.error('Error al ejecutar logout en store:', e)
              }
              this.$router.push('/login')
            }
          } catch (e) {
            console.error('Error procesando control message:', e)
          }
        })
      }
    },
    
    async fetchOnlineUsers() {
      try {
        const response = await fetch('/api/user/online')
        if (response.ok) {
          const data = await response.json()
          const normalized = this.normalizeOnlineUsers(data)
          this.onlineUsers = normalized
          console.log('Lista de usuarios en línea (normalizada):', normalized)
        }
      } catch (error) {
        console.error('Error al obtener lista de usuarios en línea:', error)
      }
    },
    
    async fetchUnreadCounts() {
      if (!this.currentUser) return
      
      try {
        const { getUnreadCount, getGroupUnreadCounts } = await import('../services/chat.service.js')
        const unreadCounts = {}
        
        for (const user of this.users) {
          if (user.id !== this.currentUser.id) {
            try {
              const response = await getUnreadCount(this.currentUser.id, user.id)
              unreadCounts[user.id] = response.data
            } catch (error) {
              console.error(`Error al obtener no leídos del usuario ${user.id}:`, error)
              unreadCounts[user.id] = 0
            }
          }
        }
        
        this.unreadCounts = unreadCounts
        
        // Obtener contadores de grupos
        try {
          const groupRes = await getGroupUnreadCounts(this.currentUser.id)
          if (groupRes.data) {
            // Asegurarse de que groupUnreadCounts es reactivo
            this.groupUnreadCounts = { ...groupRes.data }
          }
        } catch (e) {
          console.error('Error fetching group unread counts', e)
        }

        console.log('Cantidad de mensajes no leídos:', this.unreadCounts, this.groupUnreadCounts)
      } catch (error) {
        console.error('Error al obtener cantidad de no leídos:', error)
      }
    },
    
    scrollToBottom() {
      this.$nextTick(() => {
        const chatWindow = this.$refs.chatWindow
        if (chatWindow && chatWindow.$refs.messagesContainer) {
          const messagesContainer = chatWindow.$refs.messagesContainer
          messagesContainer.scrollTop = messagesContainer.scrollHeight
        }
      })
    },
    
    setupUserInteractionDetection() {
      // Detectar cualquier interacción del usuario (click, keydown, touchstart)
      const enableAudio = () => {
        this.userHasInteracted = true
        console.log('Usuario ha interactuado - AudioContext habilitado')
        
        // Remover los event listeners una vez que se detecta la interacción
        document.removeEventListener('click', enableAudio)
        document.removeEventListener('keydown', enableAudio)
        document.removeEventListener('touchstart', enableAudio)
      }
      
      document.addEventListener('click', enableAudio)
      document.addEventListener('keydown', enableAudio)
      document.addEventListener('touchstart', enableAudio)
    },
    async populateInitialLastMessages() {
      try {
        const { fetchMessages } = await import('../services/chat.service.js')
        const meId = this.currentUser && this.currentUser.id
        const users = (this.sortedUsers || this.users).filter(u => u && u.id !== undefined)
        const tasks = users.map(async (u) => {
          try {
            const res = await fetchMessages({ receiverId: u.id, userId: meId })
            const arr = Array.isArray(res.data) ? res.data : []
            if (arr.length) {
              // Ordenar por fecha para asegurar que tomamos el último
              arr.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))
              const last = arr[arr.length - 1]
              const isMine = last.sender && last.sender.id === meId
              const senderName = last.sender ? (last.sender.username || last.sender.name) : ''
              this.lastMessageMap[u.id] = { content: last.content, timestamp: last.timestamp, isMine, senderName }
            }
          } catch (e) {
            console.warn('No se pudo cargar último mensaje de usuario', u.id, e)
          }
        })
        await Promise.allSettled(tasks)
      } catch (e) {
        console.error('Error al poblar últimos mensajes iniciales:', e)
      }
    },
    
    focusComposer() {
      if (this.$refs.composerInput && typeof this.$refs.composerInput.focus === 'function') {
        this.$refs.composerInput.focus()
      }
    },
    async refreshUsers() {
      const { fetchUsers } = await import('../services/user.service.js')
      try {
        this.loadingUsers = true
        const res = await fetchUsers()
        this.users = Array.isArray(res.data) ? res.data : []
      } finally { this.loadingUsers = false }
    },
    async refreshGroups() {
      const { fetchGroups } = await import('../services/user.service.js')
      try {
        this.loadingGroups = true
        const me = this.currentUser && this.currentUser.id
        const res = await fetchGroups(me)
        this.groups = Array.isArray(res.data) ? res.data : []
      } finally { this.loadingGroups = false }
    },
    checkRouteParams() {
      const { userId, groupId } = this.$route.query
      if (userId) {
        // Esperar a que users esté cargado si es necesario, pero aquí ya debería estarlo
        // porque llamamos a checkRouteParams al final de mounted o en watch
        const u = this.users.find(x => String(x.id) === String(userId))
        if (u) {
          this.activeTab = 'contacts'
          this.selectUser(u)
        }
      } else if (groupId) {
        const g = this.groups.find(x => String(x.id) === String(groupId))
        if (g) {
          this.activeTab = 'groups'
          this.selectGroup(g)
        }
      }
    }
  },
  async mounted() {
    const { fetchUsers, fetchGroups } = await import('../services/user.service.js')
    try {
      this.loadingUsers = true
      const res = await fetchUsers()
      this.users = Array.isArray(res.data) ? res.data : []
    } finally {
      this.loadingUsers = false
    }
    try {
      this.loadingGroups = true
      const me = this.currentUser && this.currentUser.id
      const groupRes = await fetchGroups(me)
      this.groups = Array.isArray(groupRes.data) ? groupRes.data : []
    } finally {
      this.loadingGroups = false
    }
    
    // 获取初始在线用户列表
    await this.fetchOnlineUsers()
    
    // 获取未读消息数量
    await this.fetchUnreadCounts()
    
    // Poblar el último mensaje/hora para todos los usuarios al iniciar
    await this.populateInitialLastMessages()
    
    // 初始化WebSocket连接
    this.initWebSocketConnection()
    
    // Detectar interacción del usuario para habilitar AudioContext
    this.setupUserInteractionDetection()

    // Verificar parámetros de ruta al iniciar
    this.checkRouteParams()
  },
  watch: {
    '$route.query': {
      handler() {
        this.checkRouteParams()
      },
      immediate: false
    }
  },
  beforeUnmount() {
    if (this.globalSubscription) {
      this.globalSubscription.unsubscribe()
    }
    
    // Desuscribirse de todos los canales de grupo
    Object.values(this.groupSubscriptions).forEach(subscription => {
      if (subscription) {
        subscription.unsubscribe()
      }
    })
    
    disconnectWebSocket()
  }
}
</script>

<style scoped>
/* 页面整体背景渐变 */
body {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  min-height: 100vh;
}

.chat-page {
  display: flex;
  width: 100vw;
  height: 100vh;
  margin: 0;
  background: linear-gradient(145deg, var(--surface) 0%, var(--surface-alt) 100%);
  border-radius: 0;
  box-shadow: none;
  min-height: 0;
  overflow: hidden;
  backdrop-filter: none;
  border: none;
}

.content-area { display: flex; flex-direction: column; flex: 1; }
.chat-body { display: flex; flex: 1; min-height: 0; }

.topbar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 24px;
  background: linear-gradient(135deg, #ffffff 0%, #faf8f5 100%);
  border-bottom: 1px solid transparent;
  box-shadow: 0 2px 8px rgba(15,118,110,0.04);
  position: relative;
}
.topbar::after {
  content: '';
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--brand-gradient-start), var(--brand-gradient-end), var(--brand-gradient-start));
  opacity: 0.6;
}
.topbar-title {
  font-size: 24px;
  font-weight: 800;
  letter-spacing: -0.5px;
  background: linear-gradient(135deg, #1c1917 0%, var(--brand-gradient-start) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.topbar-title::before {
  content: '';
  display: inline-block;
  width: 10px; height: 10px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  margin-right: 12px;
  vertical-align: middle;
  box-shadow: 0 0 0 3px rgba(15,118,110,0.12);
  animation: topbarDot 2s cubic-bezier(0.22, 0.61, 0.36, 1) infinite;
}
@keyframes topbarDot {
  0%, 100% { box-shadow: 0 0 0 3px rgba(15,118,110,0.12); }
  50% { box-shadow: 0 0 0 6px rgba(15,118,110,0.06); }
}
.topbar-meta { color: var(--text-muted); font-weight: 600; margin-left: 12px; }
.left { display: flex; align-items: center; gap: 12px; }
.center { display: none; }
.right { display: flex; align-items: center; justify-content: flex-end; gap: 12px; }

.search { display: flex; gap: 8px; background: var(--surface-alt); padding: 8px 10px; border-radius: 12px; border: 1px solid var(--border-color); box-shadow: inset 0 1px 0 rgba(255,255,255,0.8); }
.search input { border: none; background: transparent; outline: none; min-width: 220px; font-size: 14px; }
.search-btn { border: none; background: var(--color-bg-gradient-start); color: var(--brand-gradient-start); border-radius: 10px; padding: 6px 10px; cursor: pointer; }

.add-btn { border: none; background: var(--color-bg-gradient-start); color: var(--brand-gradient-start); border-radius: 10px; padding: 8px 12px; font-weight: 700; cursor: pointer; box-shadow: var(--shadow); }
.logout-btn { border: none; background: var(--color-bg-gradient-start); color: var(--brand-gradient-start); border-radius: 10px; padding: 8px 12px; font-weight: 700; cursor: pointer; box-shadow: var(--shadow); }
.profile { display: flex; align-items: center; gap: 10px; padding-left: 8px; border-left: 1px solid var(--border-color); }
.profile-avatar { width: 28px; height: 28px; border-radius: 50%; }
.profile,
.profile-avatar,
.profile-info,
.profile-name,
.profile-sub { cursor: default; }
.profile-avatar.placeholder {
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  box-shadow: 0 2px 6px rgba(0,0,0,0.12);
}
.profile-name { font-weight: 700; color: var(--text-primary); }
.profile-sub { font-size: 12px; color: var(--text-muted); }

.sidebar {
  width: 290px;
  background: linear-gradient(180deg, #faf8f5 0%, #ffffff 100%);
  display: flex;
  flex-direction: column;
  align-items: stretch;
  border-right: 1px solid var(--border-color);
  position: relative;
}

.sidebar::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.8), transparent);
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: var(--surface);
  border-bottom: 1px solid var(--border-color);
}

.brand-logo {
  width: 28px;
  height: 28px;
}

.brand-text { display: flex; flex-direction: column; line-height: 1; }
.brand-name { font-weight: 700; color: #292524; font-size: 16px; }
.brand-sub { color: #a8a29e; font-size: 12px; }

.sidebar-user {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: linear-gradient(180deg, var(--surface-alt) 0%, var(--surface) 100%);
  color: #292524;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.2px;
  border-bottom: 1px solid var(--border-color);
  box-shadow: none;
}

.sidebar-user::after { content: none; }

.sidebar-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #a7f3d0;
  border: 2px solid #f0fdf4;
}

.sidebar-username { color: #292524; font-weight: 600; text-shadow: none; }
.sidebar-self { color: #57534e; font-size: 12px; margin-left: 4px; font-weight: 500; }

.sidebar-username {
  color: #292524;
  font-weight: 600;
  text-shadow: none;
}

.sidebar-self {
  color: #57534e;
  font-size: 12px;
  margin-left: 4px;
  font-weight: 500;
}

/* self-badge eliminado */

.chats-header {
  padding: 14px 16px 0;
  display: flex;
  align-items: baseline;
  justify-content: flex-start;
  position: relative;
}
.chats-title { display: none; }
.chats-tabs {
  display: flex;
  gap: 4px;
  background: linear-gradient(135deg, rgba(15,118,110,0.03), rgba(6,182,212,0.02));
  padding: 4px;
  border-radius: 12px;
  width: 100%;
}
.tab {
  flex: 1;
  text-align: center;
  background: transparent;
  border: none;
  color: #a8a29e;
  font-weight: 600;
  font-size: 13px;
  padding: 8px 10px;
  border-radius: 9px;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
  position: relative;
}
.tab:hover { color: var(--brand-gradient-start); background: rgba(255,255,255,0.7); }
.tab.active {
  color: #fff;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  font-weight: 700;
  box-shadow: 0 2px 10px rgba(15,118,110,0.25);
}

.chats-card {
  margin: 0;
  background: transparent;
  border-radius: 0;
  border: none;
  box-shadow: none;
  padding: 0;
}
.divider {
  height: 1px;
  margin: 4px 20px;
  background: linear-gradient(90deg, transparent, rgba(15,118,110,0.1), transparent);
  position: relative;
}
.divider::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -2px;
  transform: translateX(-50%);
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: rgba(15,118,110,0.12);
}

.main-chat {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 20px;
  background:
    radial-gradient(ellipse at 30% 20%, rgba(15,118,110,0.02) 0%, transparent 50%),
    radial-gradient(ellipse at 70% 80%, rgba(6,182,212,0.02) 0%, transparent 50%),
    linear-gradient(180deg, #faf8f5 0%, #faf8f5 100%);
  position: relative;
  min-height: 0;
}

.main-chat::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.8), transparent);
}

.chat-input-area {
  display: flex;
  gap: 12px;
  margin-top: 20px;
  padding: 16px 20px;
  background: linear-gradient(145deg, #ffffff 0%, #faf8f5 100%);
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(15,118,110,0.06), 0 1px 3px rgba(0,0,0,0.03);
  border: 1px solid rgba(15,118,110,0.06);
  transition: box-shadow 0.3s ease;
}

.chat-input-area:focus-within {
  box-shadow: 0 4px 20px rgba(15,118,110,0.1), 0 0 0 2px rgba(15,118,110,0.04);
}



.chat-input-area input {
  flex: 1;
  padding: 12px 16px;
  border-radius: 12px;
  border: 1px solid rgba(226,232,240,0.8);
  background: #fff;
  font-size: 14px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: inset 0 1px 2px rgba(0,0,0,0.02);
}

.chat-input-area input:focus {
  outline: none;
  border-color: var(--brand-gradient-start);
  box-shadow: 
    0 0 0 3px rgba(15,118,110, 0.1),
    inset 0 2px 4px rgba(0,0,0,0.02);
  transform: translateY(-1px);
}

.chat-input-area button {
  padding: 12px 20px;
  background: linear-gradient(135deg, var(--brand-gradient-start) 0%, var(--brand-gradient-end) 100%);
  color: #fff;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 600;
  font-size: 14px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 8px rgba(15,118,110,0.25);
  position: relative;
  overflow: hidden;
}

.chat-input-area button::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transform: translateX(-100%);
  transition: transform 0.5s;
  will-change: transform;
}

.chat-input-area button:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(15,118,110,0.35);
}

.chat-input-area button:hover::before {
  transform: translateX(100%);
}

.chat-input-area button:active {
  transform: translateY(0);
  box-shadow: 
    0 2px 8px rgba(15,118,110, 0.3),
    0 1px 2px rgba(0,0,0,0.1);
}

.empty-chat {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #57534e;
  padding: 24px;
  background: radial-gradient(ellipse at center, rgba(15,118,110,0.03) 0%, transparent 70%);
}
.empty-card {
  position: relative;
  width: 520px;
  max-width: 92%;
  border-radius: 24px;
  background: linear-gradient(180deg, #ffffff 0%, #faf8f5 100%);
  box-shadow:
    0 20px 50px rgba(15,118,110,0.08),
    0 4px 12px rgba(0,0,0,0.03),
    inset 0 1px 0 rgba(255,255,255,0.8);
  padding: 40px 32px 36px;
  border: 1px solid rgba(15,118,110,0.08);
  overflow: hidden;
}
.empty-card::before,
.empty-card::after {
  content: '';
  position: absolute;
  border-radius: 50%;
  filter: blur(24px);
  opacity: 0.25;
}
.empty-card::before {
  width: 200px;
  height: 200px;
  left: -50px;
  top: -50px;
  background: radial-gradient(closest-side, var(--brand-gradient-start), transparent);
  animation: emptyGlow1 6s cubic-bezier(0.22, 0.61, 0.36, 1) infinite;
}
.empty-card::after {
  width: 260px;
  height: 260px;
  right: -70px;
  bottom: -70px;
  background: radial-gradient(closest-side, var(--brand-gradient-end), transparent);
  animation: emptyGlow2 6s cubic-bezier(0.22, 0.61, 0.36, 1) infinite 1s;
}
@keyframes emptyGlow1 {
  0%, 100% { transform: translate(0, 0) scale(1); opacity: 0.25; }
  50% { transform: translate(10px, 10px) scale(1.1); opacity: 0.35; }
}
@keyframes emptyGlow2 {
  0%, 100% { transform: translate(0, 0) scale(1); opacity: 0.25; }
  50% { transform: translate(-10px, -10px) scale(1.15); opacity: 0.3; }
}

.empty-hero {
  width: 96px;
  height: 96px;
  margin: 0 auto 20px;
  border-radius: 28px;
  display: grid;
  place-items: center;
  color: #fff;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  box-shadow:
    0 12px 32px rgba(15,118,110,0.3),
    inset 0 1px 0 rgba(255,255,255,0.2);
  animation: float 3.6s cubic-bezier(0.22, 0.61, 0.36, 1) infinite;
  position: relative;
}

.empty-hero::before {
  content: '';
  position: absolute;
  inset: -8px;
  border-radius: 34px;
  border: 2px solid rgba(15,118,110,0.15);
  animation: heroRing 3s cubic-bezier(0.22, 0.61, 0.36, 1) infinite;
}

.empty-hero::after {
  content: '';
  position: absolute;
  inset: -18px;
  border-radius: 40px;
  border: 1.5px solid rgba(15,118,110,0.08);
  animation: heroRing 3s ease-in-out infinite 0.5s;
}

@keyframes heroRing {
  0%, 100% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.05); opacity: 0.5; }
}

.empty-title {
  font-weight: 800;
  color: #1c1917;
  font-size: 20px;
  letter-spacing: -0.3px;
  position: relative;
  z-index: 1;
}

.empty-sub {
  font-size: 14px;
  color: #a8a29e;
  margin-top: 8px;
  line-height: 1.5;
  position: relative;
  z-index: 1;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

.chat-input-actions {
  display: flex;
  align-items: center;
}

.icon-btn {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  border: none;
  background: #f5f0ea;
  color: #292524;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.7);
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.icon-btn:hover { background: #e7e0d7; transform: translateY(-1px); }
.icon-btn:active { transform: translateY(0); }

.image-loading { filter: blur(6px); transform: scale(1.02); }

/* 响应式设计 - 平板设备 */
@media (max-width: 1024px) {
  .chat-page {
    margin: 0;
    max-width: none;
    min-height: 600px;
  }
  
  .sidebar {
    width: 250px;
  }
  
  .sidebar-user {
    padding: 20px 0 16px 0;
    font-size: 1.1em;
  }
  
}

/* 响应式设计 - 移动设备 */
@media (max-width: 768px) {
  .chat-page {
    flex-direction: column;
    margin: 0;
    border-radius: 0;
    min-height: 100vh;
  }
  
  .sidebar {
    width: 100%;
    max-height: 200px;
    border-right: none;
    border-bottom: 1px solid rgba(226, 232, 240, 0.8);
    overflow-y: auto;
  }
  
  .sidebar-user {
    padding: 16px 0 12px 0;
    font-size: 1em;
  }
  
  .main-chat {
    flex: 1;
    min-height: 0;
  }
  
  .chat-input-area {
    padding: 16px;
    gap: 8px;
    margin-top: 12px;
  }
  
  .chat-input-area input {
    padding: 12px 16px;
    font-size: 16px; /* 防止iOS缩放 */
  }
  
  .chat-input-area button {
    padding: 12px 20px;
    font-size: 14px;
  }
}

/* 响应式设计 - 小屏幕手机 */
@media (max-width: 480px) {
  .chat-page {
    margin: 0;
    border-radius: 0;
    min-height: 100vh;
  }
  
  .sidebar {
    max-height: 150px;
  }
  
  .sidebar-user {
    padding: 12px 0 8px 0;
    font-size: 0.9em;
  }
  
  .chat-input-area {
    padding: 12px;
    gap: 6px;
    margin-top: 8px;
    border-radius: 12px;
  }
  
  .chat-input-area input {
    padding: 10px 14px;
  }
  
  .chat-input-area button {
    padding: 10px 16px;
    font-size: 13px;
  }
}

/* 横屏模式优化 */
@media (max-width: 768px) and (orientation: landscape) {
  .sidebar {
    max-height: 120px;
  }
  
  .chat-page {
    min-height: calc(100vh - 5px);
  }
}

.emoji-picker {
  margin-top: 8px;
  padding: 10px;
  background: #fff;
  border: 1px solid rgba(15,118,110,0.08);
  border-radius: 14px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.08);
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  animation: fadeIn 0.15s ease-out;
}
@keyframes fadeIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
.emoji-btn {
  padding: 6px 8px;
  border: none;
  border-radius: 8px;
  background: transparent;
  cursor: pointer;
  font-size: 18px;
  transition: all 0.15s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.emoji-btn:hover { background: linear-gradient(135deg, rgba(15,118,110,0.06), rgba(6,182,212,0.06)); transform: scale(1.2); }

  .toast {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: 1000;
    padding: 12px 18px;
    border-radius: 14px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.12);
    font-weight: 700;
    font-size: 14px;
    animation: toastSlide 0.3s ease-out;
    backdrop-filter: blur(8px);
  }
  @keyframes toastSlide {
    from { opacity: 0; transform: translateX(20px); }
    to { opacity: 1; transform: translateX(0); }
  }
  .toast-success { background: linear-gradient(135deg, #ecfdf5, #d1fae5); color: #065f46; border: 1px solid rgba(16,185,129,0.3); }
  .toast-error { background: linear-gradient(135deg, #fef2f2, #fee2e2); color: #7f1d1d; border: 1px solid rgba(239,68,68,0.3); }
  .toast-info { background: linear-gradient(135deg, #eff6ff, #dbeafe); color: #1e3a8a; border: 1px solid rgba(59,130,246,0.3); }

  .chat-page {
    width: auto;
    height: auto;
    overflow: visible;
    background:
      radial-gradient(circle at 14% 18%, rgba(15, 118, 110, 0.06), transparent 30%),
      radial-gradient(circle at 86% 82%, rgba(217, 119, 6, 0.06), transparent 24%),
      linear-gradient(145deg, #f8f4ee 0%, #fcfbf8 54%, #f4eee6 100%);
  }

  .chat-shell {
    position: relative;
    flex: 1;
    min-width: 0;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    padding: 20px 22px;
  }

  .chat-page-header {
    margin-bottom: 18px;
  }

  .chat-page-title-wrap {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .chat-page-kicker {
    margin: 0;
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: #0f766e;
  }

  .chat-page-title {
    margin: 0;
    font-size: 30px;
    font-weight: 800;
    letter-spacing: -0.05em;
    color: #1c1917;
  }

  .chat-page-subtitle {
    margin: 0;
    color: #6b6258;
    font-size: 13px;
    font-weight: 600;
  }

  .chat-workbench {
    flex: 1;
    min-height: 0;
    display: grid;
    grid-template-columns: 320px minmax(0, 1fr);
    gap: 18px;
  }

  .conversation-rail {
    min-height: 0;
    display: flex;
    flex-direction: column;
    background: linear-gradient(180deg, rgba(255,255,255,0.88) 0%, rgba(249,245,239,0.96) 100%);
    border: 1px solid rgba(120, 104, 85, 0.12);
    box-shadow: 0 14px 34px rgba(28, 18, 10, 0.06);
    border-radius: 28px;
    overflow: hidden;
  }

  .rail-header {
    padding: 16px 16px 12px;
    border-bottom: 1px solid rgba(120, 104, 85, 0.08);
  }

  .rail-title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 12px;
  }

  .rail-title {
    font-size: 17px;
    font-weight: 800;
    letter-spacing: -0.03em;
    color: #1f1a16;
  }

  .rail-subtitle {
    margin-top: 2px;
    font-size: 12px;
    color: #7a7065;
    font-weight: 600;
  }

  .chats-tabs {
    gap: 6px;
    padding: 4px;
    border-radius: 14px;
    background: rgba(15, 118, 110, 0.04);
  }

  .tab {
    border-radius: 10px;
    color: #7a7065;
    font-weight: 700;
    transition: transform 160ms cubic-bezier(0.22, 0.61, 0.36, 1), background-color 160ms cubic-bezier(0.22, 0.61, 0.36, 1), color 160ms cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 160ms cubic-bezier(0.22, 0.61, 0.36, 1);
  }

  .tab:hover {
    color: #0f766e;
    background: rgba(255,255,255,0.76);
  }

  .tab.active {
    background: linear-gradient(135deg, #0f766e, #d97706);
    box-shadow: 0 8px 18px rgba(15, 118, 110, 0.22);
  }

  .rail-body {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    padding: 10px 0 12px;
  }

  .divider {
    margin: 8px 16px 10px;
    background: linear-gradient(90deg, transparent, rgba(120, 104, 85, 0.16), transparent);
  }

  .divider::before {
    content: none;
  }

  .message-stage {
    min-width: 0;
    min-height: 0;
    display: flex;
    flex-direction: column;
  }

  .chat-input-area {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    align-items: center;
    gap: 10px;
    margin-top: 0;
    padding: 0;
    background: transparent;
    border: none;
    box-shadow: none;
  }

  .chat-input-area input {
    width: 100%;
    border: 1px solid rgba(120, 104, 85, 0.14);
    background: rgba(255,255,255,0.98);
    border-radius: 14px;
    padding: 13px 16px;
    font-size: 14px;
    color: #1f1a16;
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.8);
    transition: border-color 180ms cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 180ms cubic-bezier(0.22, 0.61, 0.36, 1);
  }

  .chat-input-area input:focus {
    outline: none;
    border-color: rgba(15, 118, 110, 0.34);
    box-shadow: 0 0 0 4px rgba(15, 118, 110, 0.08);
    transform: none;
  }

  .icon-btn {
    width: 38px;
    height: 38px;
    border-radius: 12px;
    background: #f5eee6;
    color: #574b41;
    box-shadow: none;
  }

  .icon-btn:hover {
    background: #eadfd4;
    color: #1f1a16;
  }

  .send-btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 12px 16px;
    border: none;
    border-radius: 14px;
    background: linear-gradient(135deg, #0f766e, #d97706);
    color: #fff;
    font-weight: 700;
    cursor: pointer;
    box-shadow: 0 10px 20px rgba(15, 118, 110, 0.2);
    transition: transform 180ms cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 180ms cubic-bezier(0.22, 0.61, 0.36, 1);
  }

  .send-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 14px 26px rgba(15, 118, 110, 0.26);
  }

  .send-label {
    white-space: nowrap;
  }

  .emoji-picker {
    margin-top: 10px;
    background: rgba(255,255,255,0.94);
    border: 1px solid rgba(120, 104, 85, 0.1);
    box-shadow: 0 14px 24px rgba(28, 18, 10, 0.08);
    animation: none;
  }

  .emoji-btn:hover {
    background: rgba(15, 118, 110, 0.06);
  }

  .empty-chat {
    min-height: 0;
    background: transparent;
  }

  .empty-chat-panel {
    width: min(440px, 100%);
    padding: 32px 28px;
    border-radius: 26px;
    background: linear-gradient(180deg, rgba(255,255,255,0.92), rgba(247,242,235,0.92));
    border: 1px solid rgba(120, 104, 85, 0.1);
    text-align: center;
    box-shadow: 0 16px 42px rgba(28, 18, 10, 0.06);
  }

  .empty-chat-mark {
    width: 76px;
    height: 76px;
    margin: 0 auto 16px;
    border-radius: 24px;
    display: grid;
    place-items: center;
    color: #fff;
    background: linear-gradient(135deg, #0f766e, #d97706);
    box-shadow: 0 12px 30px rgba(15, 118, 110, 0.2);
  }

  .empty-chat-title {
    font-size: 18px;
    font-weight: 800;
    color: #1f1a16;
  }

  .empty-chat-text {
    margin-top: 8px;
    font-size: 13px;
    line-height: 1.5;
    color: #6b6258;
    font-weight: 600;
  }

  .toast {
    top: 18px;
    right: 18px;
    box-shadow: 0 12px 24px rgba(28, 18, 10, 0.12);
    font-weight: 800;
    font-size: 13px;
    animation: toastSlide 220ms cubic-bezier(0.22, 0.61, 0.36, 1);
  }

  .toast-info {
    background: linear-gradient(135deg, #fff7ed, #ffedd5);
    color: #9a3412;
    border: 1px solid rgba(234,88,12,0.2);
  }

  @media (max-width: 1180px) {
    .chat-workbench {
      grid-template-columns: 290px minmax(0, 1fr);
    }
  }

  @media (max-width: 1024px) {
    .chat-shell {
      padding: 18px;
    }

    .chat-workbench {
      grid-template-columns: 270px minmax(0, 1fr);
      gap: 14px;
    }
  }

  @media (max-width: 768px) {
    .chat-page {
      flex-direction: row;
    }

    .chat-shell {
      padding: 14px;
    }

    .chat-page-title {
      font-size: 26px;
    }

    .chat-workbench {
      grid-template-columns: 1fr;
      gap: 12px;
    }

    .conversation-rail {
      max-height: 250px;
    }

    .chat-input-area {
      grid-template-columns: auto minmax(0, 1fr);
      padding: 0;
    }

    .send-btn {
      grid-column: 1 / -1;
      justify-content: center;
      width: 100%;
    }
  }

  @media (max-width: 480px) {
    .chat-shell {
      padding: 12px;
    }

    .chat-page-kicker {
      font-size: 10px;
    }

    .chat-page-title {
      font-size: 23px;
    }

    .conversation-rail {
      max-height: 220px;
      border-radius: 22px;
    }

    .emoji-picker {
      gap: 4px;
    }

    .emoji-btn {
      font-size: 17px;
      padding: 5px 7px;
    }
  }
</style>
