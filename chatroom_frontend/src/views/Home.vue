<template>
  <div class="home-page">
    <AppDock />
    <div class="home-content">
      <div class="welcome-bar" role="banner" aria-label="Welcome">
        <div class="welcome-left gap8-1">
          <div class="greeting-icon">
            <Icon :name="greetingIcon" :size="24" />
          </div>
          <div class="greeting-text welcome-copy">
            <span class="welcome-kicker">Today first</span>
            <span class="welcome-title">{{ greetingText }}</span>
            <span class="welcome-user">{{ currentUser?.username || 'Usuario' }}</span>
            <span class="welcome-subline">{{ todayEvents.length }} tasks. {{ notifications.length }} pings.</span>
          </div>
        </div>
        <div class="welcome-right welcome-stats">
          <div class="welcome-stat">
            <span class="stat-label">Now</span>
            <span class="stat-value stat-time">{{ currentTimeDisplay }}</span>
            <span class="stat-meta">{{ currentDateShort }}</span>
          </div>
          <div class="welcome-stat weather-stat" :class="weatherCard.tone">
            <span class="stat-label">Weather</span>
            <span class="stat-value">{{ weatherCard.title }}</span>
            <span class="stat-meta">{{ weatherCard.subtitle }}</span>
            <span class="weather-orb" aria-hidden="true"></span>
          </div>
        </div>
      </div>
      <div class="home-grid gap8-2">
        <!-- Columna izquierda: Calendario + Today Task -->
        <section class="calendar-card">
          <header class="card-header">
            <div class="month-title">
              {{ monthLabel }}
            </div>
            <div class="header-actions gap8-1">
              <button class="nav-btn" aria-label="Previous month" @click="prevMonth"><Icon name="chevron-left" :size="18" /></button>
              <button class="nav-btn" aria-label="Next month" @click="nextMonth"><Icon name="chevron-right" :size="18" /></button>
              <button class="today-btn" @click="goToday">Today</button>
            </div>
          </header>
          <div class="calendar">
            <div class="weekdays gap8-1">
              <span v-for="d in weekdays" :key="d">{{ d }}</span>
            </div>
            <div class="days gap8-1">
              <span v-for="(d, idx) in leadingBlanks" :key="'b'+idx" class="blank"></span>
              <button v-for="day in daysInMonth" :key="day" :class="['day', isToday(day) && 'today']">
                <span class="num">{{ day }}</span>
                <div class="dots gap8-1">
                  <span
                    v-for="(ev, i) in eventsForDay(day).slice(0,3)"
                    :key="i"
                    class="dot"
                    :style="{ background: ev.color }"
                  ></span>
                  <span v-if="eventsForDay(day).length > 3" class="more">+{{ eventsForDay(day).length - 3 }}</span>
                </div>
              </button>
            </div>
          </div>
        </section>

        <section class="tasks-card">
          <header class="card-header">
            <div class="card-title">Today Board <span class="muted">({{ todayEvents.length }})</span></div>
            <button class="add-btn" aria-label="Add" @click="openCreateForm"><Icon name="plus" :size="18" /></button>
          </header>
          <div v-if="todayEvents.length === 0" class="empty-state">
            <div class="empty-icon"><Icon name="calendar" :size="24" /></div>
            <div class="empty-text">
              <span class="strong">Quiet day.</span>
              <span class="sub">No blocks yet.</span>
            </div>
          </div>
          <ul v-else class="tasks-list gap8-1">
            <li v-for="ev in todayEvents" :key="ev.id || ev.title" class="task-item clickable" @click="openTaskDetails(ev)">
              <div class="task-info">
                <span class="task-marker" :style="{ backgroundColor: ev.color || '#0f766e' }"></span>
                <span class="task-title">{{ ev.title }}</span>
              </div>
              <span class="time">{{ ev.time || 'All day' }}</span>
            </li>
          </ul>
        </section>

        <!-- Columna derecha: Notification + Team Chat -->
        <section class="notification-card">
          <header class="card-header">
            <div class="card-title">Notifications <span class="muted">({{ notifications.length }})</span></div>
            <router-link to="/chat" class="view-all">Open chat</router-link>
          </header>
          <div class="notice empty-notice" v-if="notifications.length === 0">
            <div class="notice-content">
              <div class="notice-icon"><Icon name="bell" :size="32" /></div>
              <div class="notice-header">
                <div class="notice-title">All clear.</div>
                <div class="notice-date">Nobody needs you yet.</div>
              </div>
            </div>
          </div>
          <ul class="notifications-list gap8-2" v-else>
            <li class="notification-item" v-for="n in notifications" :key="n.key">
              <div class="notification-main">
                <div class="notification-title gap8-1">
                  <span class="badge" :class="n.type">{{ n.type === 'group' ? 'Group' : 'Message' }}</span>
                  <span class="strong">{{ n.title }}</span>
                </div>
                <div class="notification-text">{{ n.text }}</div>
                <div class="notification-meta">{{ n.when }}</div>
              </div>
              <div class="notification-actions">
                <button class="assign-btn" @click="viewNotification(n)">View</button>
              </div>
            </li>
          </ul>
        </section>

      </div>
    </div>

    <!-- Modal de Creación de Evento -->
    <div v-if="showCreateModal" class="modal-overlay">
      <div class="modal-card">
        <header class="modal-header">
          <h3 class="modal-title">Add today's block</h3>
          <button class="close-btn" @click="cancelCreate">×</button>
        </header>
        <div class="modal-body">
          <div class="form-row">
            <label>Title*</label>
            <input type="text" v-model="newEvent.title" placeholder="What do you need to do today?" ref="titleInput" />
          </div>
          <div class="form-row">
            <label>Description</label>
            <textarea v-model="newEvent.description" placeholder="Extra details..."></textarea>
          </div>
          <div class="form-grid gap8-2">
            <div>
              <label>Time</label>
              <div class="hour-selects">
                <select v-model="newEvent.startHour">
                  <option :value="null">Start</option>
                  <option v-for="h in hours24" :key="'sh-'+h" :value="h">{{ pad2(h) }}:00</option>
                </select>
                <span class="sep">-</span>
                <select v-model="newEvent.endHour">
                  <option :value="null">End</option>
                  <option v-for="h in hours24" :key="'eh-'+h" :value="h">{{ pad2(h) }}:00</option>
                </select>
              </div>
            </div>
            <div>
              <label>Color</label>
              <div class="color-picker-wrapper">
                <input v-model="newEvent.color" type="color" />
              </div>
            </div>
          </div>
          <div class="form-row">
            <label>Assignees</label>
            <div class="checkbox-list">
              <label v-for="u in users" :key="u.id" class="checkbox-item">
                <input type="checkbox" :value="u.id" v-model="newEvent.assignedToIds" />
                <span class="checkbox-label">{{ u.username }}</span>
              </label>
            </div>
          </div>
          <div v-if="createError" class="form-error">{{ createError }}</div>
        </div>
        <footer class="modal-footer">
          <button class="btn-cancel" @click="cancelCreate">Cancel</button>
          <button class="btn-primary" @click="submitCreate">Save block</button>
        </footer>
      </div>
    </div>

    <!-- Modal de Detalle de Evento -->
    <div v-if="showDetailModal && selectedTask" class="modal-overlay" @click.self="closeTaskDetails">
      <div class="modal-card detail-card-home">
        <header class="modal-header" :style="{ borderLeft: `6px solid ${selectedTask.color || '#0f766e'}` }">
          <div class="header-content">
             <h3 class="modal-title">{{ selectedTask.title }}</h3>
             <span class="modal-subtitle">{{ currentDateFull }}</span>
          </div>
          <button class="close-btn" @click="closeTaskDetails">×</button>
        </header>
        <div class="modal-body">
          <div class="detail-row">
            <div class="detail-icon"><Icon name="clock" :size="18" /></div>
            <div class="detail-text">
              <span class="label">Time</span>
              <span class="value">{{ selectedTask.time || 'All day' }}</span>
            </div>
          </div>
          
          <div class="detail-row" v-if="selectedTask.description">
            <div class="detail-icon"><Icon name="file-text" :size="18" /></div>
            <div class="detail-text">
              <span class="label">Description</span>
              <span class="value description">{{ selectedTask.description }}</span>
            </div>
          </div>

          <div class="detail-row">
             <div class="detail-icon"><Icon name="user" :size="18" /></div>
             <div class="detail-text">
               <span class="label">Created by</span>
               <span class="value">{{ selectedTask.createdBy ? selectedTask.createdBy.username : (selectedTask.createdById ? usernameById(selectedTask.createdById) : '—') }}</span>
             </div>
          </div>

          <div class="detail-row" v-if="(selectedTask.responsibles && selectedTask.responsibles.length) || (selectedTask.responsibleIds && selectedTask.responsibleIds.length)">
             <div class="detail-icon"><Icon name="users" :size="18" /></div>
             <div class="detail-text">
               <span class="label">Assignees</span>
               <div class="responsibles-list">
                 <template v-if="selectedTask.responsibles && selectedTask.responsibles.length">
                    <span v-for="u in selectedTask.responsibles" :key="u.id" class="responsible-badge">{{ u.username }}</span>
                 </template>
                 <template v-else>
                    <span v-for="id in selectedTask.responsibleIds" :key="id" class="responsible-badge">{{ usernameById(id) }}</span>
                 </template>
               </div>
             </div>
          </div>
        </div>
        <footer class="modal-footer">
          <button class="btn-primary" @click="closeTaskDetails">Close</button>
        </footer>
      </div>
    </div>
  </div>
</template>

<script>
import AppDock from '../components/AppDock.vue'
import Icon from '../components/Icon.vue'
import { mapGetters } from 'vuex'
import { fetchMonthEvents, createEvent } from '../services/events.service.js'
import { connectWebSocket, subscribe, disconnectWebSocket } from '../services/websocket.js'
import { markMessagesAsRead } from '../services/chat.service.js'
import { fetchGroups, fetchUsers } from '../services/user.service.js'
export default {
  name: 'Home',
  components: { AppDock, Icon },
  data() {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth() // 0-11
    const first = new Date(year, month, 1)
    const last = new Date(year, month + 1, 0)
    return {
      year,
      month,
      todayDay: now.getDate(),
      todayMonth: month,
      todayYear: year,
      weekdays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      leadingBlanks: Array(first.getDay()).fill(0),
      daysInMonth: Array.from({ length: last.getDate() }, (_, i) => i + 1),
      events: [],
      notifications: [],
      quickNote: '',
      saveStatus: '',
      wsConnected: false,
      globalSubscription: null,
      groupSubscriptions: {},
      groups: [],
      // Event Creation Data
      showCreateModal: false,
      createError: '',
      newEvent: { title: '', description: '', time: '', color: '#0f766e', assignedToIds: [], startHour: null, endHour: null },
      users: [],
      // Task Details
      showDetailModal: false,
      selectedTask: null,
      nowTick: Date.now(),
      nowTimer: null
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    monthLabel() {
      const m = ['January','February','March','April','May','June','July','August','September','October','November','December'][this.month]
      return `${m}, ${this.year}`
    },
    todayISO() {
      return this.toISO(this.todayYear, this.todayMonth, this.todayDay)
    },
    todayEvents() {
      const uid = this.currentUser?.id
      if (!uid) return []
      return this.events.filter(e => {
        const isToday = (e.date || '') === this.todayISO
        if (!isToday) return false
        
        // Filtrar por asignación: mostrar solo si el usuario actual está asignado
        const assignedIds = (e.responsibleIds || []).map(String)
        const assignedObjs = (e.responsibles || []).map(u => String(u.id))
        
        // Combinar ambas listas de IDs por seguridad
        const allAssigned = [...new Set([...assignedIds, ...assignedObjs])]
        
        // Si no hay responsables, ¿se muestra? 
        // Según la petición "solo aparecen para los que estan asignado", 
        // si nadie está asignado, nadie lo ve en Today Task (pero sí en calendario).
        // Si queremos que el creador lo vea por defecto si no hay asignados, descomentar:
        // if (allAssigned.length === 0) return String(e.createdById) === String(uid)
        
        return allAssigned.includes(String(uid))
      })
    },
    greetingText() {
      const h = new Date().getHours()
      if (h < 12) return 'Good morning,'
      if (h < 20) return 'Good afternoon,'
      return 'Good evening,'
    },
    greetingIcon() {
      const h = new Date().getHours()
      if (h >= 6 && h < 18) return 'sun'
      return 'moon'
    },
    currentDateFull() {
      const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
      return new Date(this.nowTick).toLocaleDateString('en-US', options)
    },
    currentDateShort() {
      const options = { weekday: 'long', month: 'long', day: 'numeric' }
      return new Date(this.nowTick).toLocaleDateString('en-US', options)
    },
    currentTimeDisplay() {
      const now = new Date(this.nowTick)
      return now.toLocaleTimeString('en-GB', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    },
    weatherCard() {
      const now = new Date(this.nowTick)
      const month = now.getMonth()
      const hour = now.getHours()

      const season =
        month <= 1 || month === 11 ? 'winter'
          : month <= 4 ? 'spring'
            : month <= 7 ? 'summer'
              : 'autumn'

      if (hour >= 19 || hour < 6) {
        return {
          title: season === 'winter' ? 'Cold night' : 'Calm night',
          subtitle: season === 'summer' ? 'Warm air, low noise.' : 'Dim sky, slower pace.',
          tone: 'night'
        }
      }

      if (season === 'summer') {
        return {
          title: 'Clear sky',
          subtitle: 'Bright light. Long day.',
          tone: 'summer'
        }
      }

      if (season === 'spring') {
        return {
          title: 'Soft clouds',
          subtitle: 'Fresh air. Easy pace.',
          tone: 'spring'
        }
      }

      if (season === 'autumn') {
        return {
          title: 'Dry breeze',
          subtitle: 'Muted light. Sharp focus.',
          tone: 'autumn'
        }
      }

      return {
        title: 'Cool light',
        subtitle: 'Clean air. Quiet room.',
        tone: 'winter'
      }
    },
    hours24() {
      return Array.from({ length: 24 }, (_, i) => i)
    }
  },
  methods: {
    toISO(y,m,d) { return `${y}-${String(m+1).padStart(2,'0')}-${String(d).padStart(2,'0')}` },
    // Event Creation Methods
    openCreateForm() {
      this.showCreateModal = true
      this.createError = ''
      if (!this.newEvent.color) this.newEvent.color = '#0f766e'
      this.loadUsers()
    },
    cancelCreate() {
      this.showCreateModal = false
      this.createError = ''
      this.newEvent = { title: '', description: '', time: '', color: '#0f766e', assignedToIds: [], startHour: null, endHour: null }
    },
    openTaskDetails(task) {
      this.selectedTask = task
      this.showDetailModal = true
    },
    closeTaskDetails() {
      this.showDetailModal = false
      this.selectedTask = null
    },
    pad2(n) { return String(n).padStart(2,'0') },
    async loadUsers() {
      try {
        const res = await fetchUsers()
        // Filtrar SUPER_ADMIN para que no aparezca como opción de responsable
        this.users = (Array.isArray(res?.data) ? res.data : []).filter(u => u.role !== 'SUPER_ADMIN')
      } catch (e) {
        console.warn('No se pudieron cargar usuarios', e)
      }
    },
    usernameById(id) {
      const u = this.users.find(x => String(x.id) === String(id))
      return u ? u.username : id
    },
    async submitCreate() {
      const title = (this.newEvent.title || '').trim()
      if (!title) { this.createError = 'Title is required'; return }
      
      let timeStr = null
      const sh = this.newEvent.startHour
      const eh = this.newEvent.endHour
      if (sh != null || eh != null) {
        if (sh == null || eh == null) {
          this.createError = 'Pick start and end time'; return
        }
        if (Number(eh) < Number(sh)) {
          this.createError = 'End time can\'t be before start'; return
        }
        timeStr = `${this.pad2(Number(sh))}:00 - ${this.pad2(Number(eh))}:00`
      }
      
      const payload = {
        title,
        description: (this.newEvent.description || '').trim() || null,
        time: timeStr,
        color: this.newEvent.color || '#0f766e',
        date: this.todayISO, // Siempre para hoy
        createdById: this.currentUser?.id || null,
        responsibleIds: Array.isArray(this.newEvent.assignedToIds) ? this.newEvent.assignedToIds : []
      }
      
      try {
        const created = await createEvent(payload)
        if (created) {
          await this.loadMonth() // Recargar eventos
          this.cancelCreate()
        }
      } catch (e) {
        const msg = e?.response?.data?.message || 'Could not save event'
        this.createError = msg
      }
    },
    recalcCalendar() {
      const first = new Date(this.year, this.month, 1)
      const last = new Date(this.year, this.month + 1, 0)
      this.leadingBlanks = Array(first.getDay()).fill(0)
      this.daysInMonth = Array.from({ length: last.getDate() }, (_, i) => i + 1)
    },
    eventsForDay(day) {
      const key = this.toISO(this.year, this.month, day)
      return this.events.filter(e => (e.date || '') === key)
    },
    async loadMonth() {
      try {
        const data = await fetchMonthEvents(this.year, this.month + 1)
        if (Array.isArray(data)) {
          this.events = data
          return
        }
      } catch (e) {
        // fallback ya gestionado en el servicio
      }
      const data = await fetchMonthEvents(this.year, this.month + 1)
      this.events = Array.isArray(data) ? data : []
    },
    async loadNotifications() {
      if (!this.currentUser) return
      try {
        const { fetchNotifications } = await import('../services/chat.service.js')
        const res = await fetchNotifications(this.currentUser.id)
        if (Array.isArray(res.data)) {
          this.notifications = res.data.map(msg => {
            const isGroup = !!msg.group
            const senderId = (msg.sender && (msg.sender.id ?? msg.sender.userId)) || msg.senderId
            const senderName = (msg.sender && msg.sender.username) || 'User'
            const title = isGroup 
              ? (msg.group.name || `Group ${msg.group.id}`)
              : senderName
            
            let text = msg.content || ''
            if (!text) {
              if (msg.type === 'image') text = 'Photo'
              else if (msg.type === 'file') text = 'File'
              else text = '[Message]'
            }

            return {
              key: `${isGroup ? 'group' : 'user'}-${isGroup ? msg.group.id : senderId}-${msg.id}`,
              type: isGroup ? 'group' : 'user',
              title,
              text,
              when: this.formatTime(msg.timestamp),
              senderId: !isGroup ? senderId : null,
              groupId: isGroup ? msg.group.id : null
            }
          })
        }
      } catch (e) {
        console.warn('Error loading notifications:', e)
      }
    },
    saveNote() {
      if (this.currentUser && this.currentUser.id) {
        localStorage.setItem(`user_quick_note_${this.currentUser.id}`, this.quickNote)
        this.saveStatus = 'Saved'
        setTimeout(() => { this.saveStatus = '' }, 2000)
      }
    },
    clearNote() {
      if (confirm('Clear all notes?')) {
        this.quickNote = ''
        this.saveNote()
      }
    },
    prevMonth() {
      if (this.month === 0) {
        this.month = 11
        this.year -= 1
      } else {
        this.month -= 1
      }
      this.recalcCalendar()
      this.loadMonth()
    },
    nextMonth() {
      if (this.month === 11) {
        this.month = 0
        this.year += 1
      } else {
        this.month += 1
      }
      this.recalcCalendar()
    },
    goToday() {
      const now = new Date()
      this.year = now.getFullYear()
      this.month = now.getMonth()
      this.recalcCalendar()
    },
    isToday(day) {
      return this.year === this.todayYear && this.month === this.todayMonth && day === this.todayDay
    },
    initWebSocketConnection() {
      if (!this.currentUser) return
      connectWebSocket(window.location.origin + '/ws', this.currentUser.username, null, () => {
        this.wsConnected = true
        // Suscripción a mensajes directos del usuario
        this.subscribeToGlobalUserChannel()
        // Suscripción a actualizaciones públicas
        this.subscribeToPublicChannel()
        // Suscripción a canales de grupo
        this.subscribeToAllGroupChannels()
      }, (err) => {
        console.error('Error de WebSocket en Home:', err)
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
          // Si hay lógica para actualizar listas de usuarios/amigos, iría aquí
        }
      })
    },
    subscribeToGlobalUserChannel() {
      const topic = '/user/queue/messages'
      this.globalSubscription = subscribe(topic, (msg) => {
        const senderId = (msg && msg.sender && (msg.sender.id ?? msg.sender.userId)) || msg.senderId
        const senderName = (msg && msg.sender && msg.sender.username) || 'User'
        let text = (msg && msg.content) || ''
        if (!text) {
          if (msg.type === 'image') text = 'Photo'
          else if (msg.type === 'file') text = 'File'
          else text = '[Message]'
        }
        const when = this.formatTime(msg && msg.timestamp)
        const key = `user-${senderId}-${msg.id || when}`
        this.notifications.unshift({
          key,
          type: 'user',
          title: senderName,
          text,
          when,
          senderId
        })
      })
    },
    async loadGroups() {
      try {
        const res = await fetchGroups()
        this.groups = Array.isArray(res.data) ? res.data : []
      } catch (e) {
        this.groups = []
      }
    },
    subscribeToGroupChannel(groupId) {
      const topic = `/topic/group/${groupId}`
      if (this.groupSubscriptions[groupId]) {
        this.groupSubscriptions[groupId].unsubscribe()
      }
      this.groupSubscriptions[groupId] = subscribe(topic, (msg) => {
        const group = msg && msg.group
        const title = (group && (group.name || `Group ${group.id}`)) || `Group ${groupId}`
        let text = (msg && msg.content) || ''
        if (!text) {
          if (msg.type === 'image') text = 'Photo'
          else if (msg.type === 'file') text = 'File'
          else text = '[Group message]'
        }
        const when = this.formatTime(msg && msg.timestamp)
        const key = `group-${groupId}-${msg.id || when}`
        this.notifications.unshift({
          key,
          type: 'group',
          title,
          text,
          when,
          groupId
        })
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
    formatTime(ts) {
      try {
        const d = ts ? new Date(ts) : new Date()
        return d.toLocaleString()
      } catch (e) {
        return '—'
      }
    },
    async viewNotification(n) {
      try {
        if (n.type === 'user' && this.currentUser && n.senderId != null) {
          await markMessagesAsRead(this.currentUser.id, n.senderId)
          // Eliminar todas las notificaciones del mismo remitente
          this.notifications = this.notifications.filter(x => !(x.type === 'user' && x.senderId === n.senderId))
        } else if (n.type === 'group' && n.groupId != null) {
          // Eliminar notificaciones del grupo
          this.notifications = this.notifications.filter(x => !(x.type === 'group' && x.groupId === n.groupId))
        }
      } catch (e) {
        console.warn('No se pudo marcar como leído:', e)
      }
      // Navegar a chat para ver el mensaje
      const query = {}
      if (n.type === 'user' && n.senderId) query.userId = n.senderId
      if (n.type === 'group' && n.groupId) query.groupId = n.groupId
      this.$router.push({ path: '/chat', query })
    },
    handleKeydown(e) {
      if (e.key === 'Escape') {
        if (this.showDetailModal) this.closeTaskDetails()
        if (this.showCreateModal) this.cancelCreate()
      }
    }
  },
  async mounted() {
    window.addEventListener('keydown', this.handleKeydown)
    this.nowTimer = window.setInterval(() => {
      this.nowTick = Date.now()
    }, 1000)
    if (this.currentUser && this.currentUser.id) {
      this.quickNote = localStorage.getItem(`user_quick_note_${this.currentUser.id}`) || ''
    }
    await this.loadMonth()
    await this.loadNotifications()
    await this.loadGroups()
    this.initWebSocketConnection()
  },
  watch: {
    month() { this.loadMonth() },
    year() { this.loadMonth() },
    currentUser(newUser) {
      if (newUser && newUser.id) {
        this.quickNote = localStorage.getItem(`user_quick_note_${newUser.id}`) || ''
      }
    }
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this.handleKeydown)
    if (this.nowTimer) window.clearInterval(this.nowTimer)
    try {
      if (this.globalSubscription) this.globalSubscription.unsubscribe()
      Object.values(this.groupSubscriptions).forEach(s => s && s.unsubscribe())
      disconnectWebSocket()
    } catch (e) {
      console.error('Error al limpiar suscripciones en Home:', e)
    }
  }
}
</script>

<style scoped>
.home-page { display: flex; min-height: 100vh; background: linear-gradient(135deg, #faf8f5 0%, #f0fdf4 50%, #faf8f5 100%); }
.home-content { flex: 1; padding: 24px; max-width: 1600px; margin: 0 auto; }

/* Animations */
@keyframes slideUpFade {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.welcome-bar {
  display: flex; align-items: center; justify-content: space-between;
  background: linear-gradient(135deg, #ffffff 0%, #faf8f5 100%);
  color: #1c1917; border-radius: 20px; padding: 20px 24px;
  box-shadow: 0 4px 24px rgba(15,118,110,0.06), 0 1px 3px rgba(0,0,0,0.03);
  margin-bottom: 24px;
  border: 1px solid rgba(15,118,110,0.06);
  animation: slideUpFade 0.5s cubic-bezier(0.22, 0.61, 0.36, 1) both;
  position: relative;
  overflow: hidden;
  transition: box-shadow 0.3s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.welcome-bar:hover { box-shadow: 0 8px 32px rgba(15,118,110,0.1), 0 1px 3px rgba(0,0,0,0.03); }

/* Decoration line */
.welcome-bar::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 6px;
  background: linear-gradient(180deg, var(--brand-gradient-start), var(--brand-gradient-end));
}

.welcome-left { display: flex; align-items: center; gap: 16px; }
.greeting-icon {
  background: linear-gradient(135deg, #f0fdf4, #d1fae5);
  color: var(--brand-gradient-start);
  width: 48px; height: 48px; border-radius: 16px;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 12px rgba(15,118,110,0.03);
}
.greeting-text { display: flex; flex-direction: column; gap: 2px; }
.welcome-title { font-weight: 600; color: #57534e; font-size: 0.9rem; }
.welcome-user { font-weight: 800; font-size: 1.25rem; color: #1c1917; letter-spacing: -0.5px; }
.welcome-right { font-weight: 600; font-size: 0.95rem; color: #44403c; text-align: right; background: #faf8f5; padding: 8px 16px; border-radius: 12px; }
.current-date { text-transform: capitalize; }

.empty-state {
  flex: 1; height: 100%;
  display: flex; /* Asegurar display flex para align-items */
  justify-content: center; flex-direction: column; gap: 12px;
  padding: 40px 20px; color: #a8a29e; background: transparent;
  border: none;
  transition: all 0.2s;
  align-items: center; /* Centrado horizontal del contenido flex */
}
.empty-state:hover { background: transparent; }
.empty-icon { color: #d6d3d1; margin-bottom: 4px; }
.empty-text { text-align: center; display: flex; flex-direction: column; gap: 4px; }
.empty-text .strong { font-weight: 700; color: #44403c; font-size: 1rem; }
.empty-text .sub { font-size: 0.85rem; }

.notice.empty-notice {
  flex: 1; height: 100%;
  background: transparent; border: none;
  display: flex; align-items: center; justify-content: center;
  padding: 40px 20px;
  color: #57534e; box-shadow: none;
}
.notice-content { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; }
.notice-icon { background: #e7e0d7; color: #a8a29e; padding: 12px; border-radius: 50%; }
.notice-header { display: flex; flex-direction: column; gap: 4px; }
.notice-title { font-weight: 700; font-size: 1rem; color: #44403c; margin: 0; }
.notice-date { font-weight: 500; font-size: 0.85rem; opacity: 0.8; }

.home-grid { display: grid; grid-template-columns: 1.2fr 1fr; gap: 24px; }

.card-header { display: flex; justify-content: space-between; align-items: center; padding: 16px 20px; border-bottom: 1px solid #f5f0ea; }
.month-title, .card-title { font-weight: 800; color: #1c1917; font-size: 1.1rem; letter-spacing: -0.3px; }
.muted { color: #a8a29e; font-weight: 600; font-size: 0.9em; margin-left: 4px; }
.header-actions { display: flex; align-items: center; gap: 8px; }
.nav-btn, .dots-btn, .add-btn {
  border: 1px solid #e7e0d7; background: #fff; cursor: pointer; color: #57534e;
  border-radius: 10px; padding: 6px; transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
  display: flex; align-items: center; justify-content: center;
  width: 32px; height: 32px;
}
.nav-btn:hover, .dots-btn:hover, .add-btn:hover {
  background: #faf8f5; border-color: #d6d3d1; color: var(--brand-gradient-start); transform: translateY(-1px);
}
.add-btn { background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end)); color: #fff; border: none; }
.add-btn:hover { background: linear-gradient(135deg, var(--brand-gradient-end), var(--brand-gradient-start)); color: #fff; box-shadow: 0 4px 14px rgba(15,118,110,0.35); border-color: transparent; }

.view-all {
  color: var(--brand-gradient-start); text-decoration: none; font-weight: 600; font-size: 0.9rem;
  padding: 4px 12px; background: #f0fdf4; border-radius: 20px; transition: all 0.2s;
}
.view-all:hover { background: #d1fae5; transform: translateY(-1px); }

.calendar-card, .tasks-card, .notification-card, .quicknotes-card {
  background: #fff;
  border: 1px solid #f5f0ea;
  border-radius: 24px;
  box-shadow: 0 10px 30px -10px rgba(0,0,0,0.05);
  transition: transform 0.3s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.3s cubic-bezier(0.22, 0.61, 0.36, 1);
  animation: slideUpFade 0.5s cubic-bezier(0.22, 0.61, 0.36, 1) both;
  overflow: hidden;
}

/* Staggered animation delays */
.calendar-card { animation-delay: 0.1s; }
.tasks-card { animation-delay: 0.2s; }
.notification-card { animation-delay: 0.3s; }
.quicknotes-card { animation-delay: 0.4s; }

.calendar-card:hover, .tasks-card:hover, .notification-card:hover, .quicknotes-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 40px -10px rgba(15,118,110,0.1), 0 0 0 1px rgba(15,118,110,0.04);
}

/* Custom Scrollbar for lists */
.tasks-list::-webkit-scrollbar,
.notifications-list::-webkit-scrollbar,
.quicknotes-card .notes-content textarea::-webkit-scrollbar { width: 5px; }
.tasks-list::-webkit-scrollbar-track,
.notifications-list::-webkit-scrollbar-track,
.quicknotes-card .notes-content textarea::-webkit-scrollbar-track { background: transparent; }
.tasks-list::-webkit-scrollbar-thumb,
.notifications-list::-webkit-scrollbar-thumb,
.quicknotes-card .notes-content textarea::-webkit-scrollbar-thumb { background-color: #e7e0d7; border-radius: 10px; }
.tasks-list::-webkit-scrollbar-thumb:hover,
.notifications-list::-webkit-scrollbar-thumb:hover,
.quicknotes-card .notes-content textarea::-webkit-scrollbar-thumb:hover { background-color: #d6d3d1; }

.calendar { padding: 20px 24px 24px; }
.weekdays { display: grid; grid-template-columns: repeat(7,1fr); color: #a8a29e; font-weight: 700; font-size: 0.75rem; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 1px; }
.weekdays span { text-align: center; }
.days { display: grid; grid-template-columns: repeat(7,1fr); gap: 8px; }
.day {
  border: 1px solid transparent; background: transparent; border-radius: 14px;
  padding: 0; height: 48px; display: flex; flex-direction: column; align-items: center; justify-content: center;
  color: #292524; font-weight: 600; cursor: pointer; position: relative; transition: all 0.2s;
}
.day:hover:not(.today) { background: #f5f0ea; color: var(--brand-gradient-start); transform: scale(1.05); }
.day.today {
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  color: #fff; border: none;
  box-shadow: 0 8px 20px rgba(15,118,110,0.3);
  transform: scale(1.05);
}
.blank { height: 48px; }

.num { font-weight: 600; font-size: 0.95rem; z-index: 1; }
.dots { position: absolute; bottom: 6px; left: 0; right: 0; display: flex; justify-content: center; gap: 3px; }
.dot { width: 4px; height: 4px; border-radius: 50%; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
.more { font-size: 9px; color: #a8a29e; font-weight: 700; }
.day.today .more { color: rgba(255,255,255,0.8); }

.tasks-card {
  display: flex; flex-direction: column;
  min-height: 320px;
  height: 100%;
}
.tasks-list { list-style: none; margin: 0; padding: 16px 20px 20px; display: flex; flex-direction: column; flex: 1; overflow-y: auto; gap: 10px; }
.task-item {
  display: flex; justify-content: space-between; align-items: center;
  background: #fff; border: 1px solid #f5f0ea; border-radius: 12px; padding: 12px 16px;
  transition: all 0.2s; box-shadow: 0 2px 5px rgba(0,0,0,0.02);
}
.task-item:hover { border-color: rgba(15,118,110,0.15); transform: translateX(4px); box-shadow: 0 4px 16px rgba(15,118,110,0.08); background: linear-gradient(90deg, rgba(15,118,110,0.02) 0%, transparent 100%); }
.task-item label { display: flex; align-items: center; gap: 12px; font-weight: 600; color: #292524; cursor: pointer; font-size: 0.95rem; }
.task-item input[type="checkbox"] {
  accent-color: var(--brand-gradient-start); width: 18px; height: 18px; cursor: pointer;
  border-radius: 6px; border: 2px solid #d6d3d1;
}

.time { color: #57534e; font-weight: 600; font-size: 0.75rem; background: #f5f0ea; padding: 4px 8px; border-radius: 6px; }

.notice { margin: 0; padding: 0; border-radius: 0; color: inherit; background: transparent; position: relative; box-shadow: none; }
.notice-title { font-weight: 700; margin-bottom: 0; font-size: 1rem; }

.assign-btn {
  background: #fff; color: var(--brand-gradient-start); border: 1px solid #e7e0d7;
  border-radius: 8px; padding: 6px 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; font-size: 0.8rem;
}
.assign-btn:hover { background: #f0fdf4; border-color: #d1fae5; }

.notification-card {
  display: flex; flex-direction: column;
  min-height: 320px;
  height: 100%;
}
.notifications-list { list-style: none; margin: 0; padding: 16px 20px; display: flex; flex-direction: column; gap: 12px; flex: 1; overflow-y: auto; }
.notification-item {
  display: flex; justify-content: space-between; align-items: flex-start;
  background: #fff; border: 1px solid #f5f0ea; border-radius: 16px; padding: 16px;
  transition: all 0.2s; box-shadow: 0 2px 5px rgba(0,0,0,0.02);
}
.notification-item:hover { background: linear-gradient(90deg, rgba(15,118,110,0.02) 0%, transparent 100%); border-color: rgba(15,118,110,0.12); transform: translateY(-2px); box-shadow: 0 8px 20px rgba(15,118,110,0.06); }
.notification-main { display: flex; flex-direction: column; gap: 6px; }
.notification-title { display: flex; align-items: center; font-weight: 700; color: #1c1917; font-size: 0.95rem; gap: 8px; }
.notification-text { color: #44403c; font-weight: 500; font-size: 0.9rem; line-height: 1.5; }
.notification-meta { color: #a8a29e; font-weight: 600; font-size: 0.75rem; margin-top: 4px; }
.badge { display: inline-block; padding: 4px 8px; border-radius: 6px; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; }
.badge.user { background: #f0fdf4; color: #0f766e; }
.badge.group { background: #fef2f2; color: #dc2626; }

.action-btn {
  border: none; border-radius: 10px; padding: 8px 16px; cursor: pointer; font-weight: 600;
  display: flex; align-items: center; gap: 8px; font-size: 0.85rem; transition: all 0.2s;
}
.save-btn { background: #10b981; color: #fff; box-shadow: 0 4px 10px rgba(16, 185, 129, 0.2); }
.save-btn:hover { background: #059669; transform: translateY(-1px); box-shadow: 0 6px 15px rgba(16, 185, 129, 0.3); }
.clear-btn { background: #fff; border: 1px solid #fee2e2; color: #ef4444; padding: 8px 12px; }
.clear-btn:hover { background: #fef2f2; border-color: #fecaca; transform: translateY(-1px); }

.quicknotes-card .notes-content { padding: 20px; display: flex; flex-direction: column; height: 280px; background: #fff; }
.quicknotes-card textarea {
  flex: 1; width: 100%; border: 2px solid #f5f0ea; border-radius: 16px; padding: 16px;
  resize: none; font-family: 'DM Sans', sans-serif; font-size: 0.95rem; outline: none;
  background: #fff; color: #292524; line-height: 1.6; transition: all 0.2s;
  background-image: linear-gradient(#f5f0ea 1px, transparent 1px);
  background-size: 100% 32px;
  line-height: 32px;
  padding-top: 7px; /* Adjust to align text with lines */
}
.quicknotes-card textarea:focus {
  border-color: #e7e0d7;
  box-shadow: 0 0 0 4px #f5f0ea;
}
.save-status { font-size: 12px; color: #10b981; font-weight: 700; animation: fadeOut 2s forwards; margin-right: 8px; background: #ecfdf5; padding: 4px 10px; border-radius: 20px; }

@keyframes fadeOut {
  0% { opacity: 1; } 70% { opacity: 1; } 100% { opacity: 0; }
}

.right-actions { display: flex; align-items: center; gap: 12px; }

.today-btn {
  background: #fff; border: 1px solid #e7e0d7; color: #57534e;
  font-weight: 600; font-size: 0.85rem; cursor: pointer; padding: 6px 16px;
  border-radius: 8px; transition: all 0.2s; height: 32px; display: flex; align-items: center;
}
.today-btn:hover { background: #faf8f5; color: #1c1917; border-color: #d6d3d1; }

@media (max-width: 1200px) {
  .home-grid { grid-template-columns: 1fr; max-width: 800px; margin: 0 auto; }
}

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(15,23,42,0.5); z-index: 1000;
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
  backdrop-filter: blur(6px);
  animation: fadeIn 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.modal-card {
  background: #fff; width: 100%; max-width: 480px; border-radius: 20px;
  box-shadow: 0 25px 60px rgba(0,0,0,0.2);
  display: flex; flex-direction: column; max-height: 90vh; overflow: hidden;
  animation: modalSlideUp 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes modalSlideUp {
  from { opacity: 0; transform: translateY(16px) scale(0.97); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
.modal-header {
  padding: 16px 20px; border-bottom: 1px solid #f5f0ea; display: flex;
  justify-content: space-between; align-items: center; background: #fafafa;
}
.modal-title { font-weight: 800; color: #1c1917; font-size: 1.1rem; margin: 0; }
.close-btn { background: none; border: none; font-size: 1.5rem; color: #a8a29e; cursor: pointer; line-height: 1; padding: 0 4px; }
.close-btn:hover { color: #ef4444; }

.modal-body { padding: 20px; overflow-y: auto; flex: 1; display: flex; flex-direction: column; gap: 16px; }
.form-row { display: flex; flex-direction: column; gap: 6px; }
.form-row label { font-weight: 600; font-size: 0.9rem; color: #44403c; }
.form-row input[type="text"],
.form-row textarea {
  width: 100%; padding: 10px 12px; border: 1px solid #d6d3d1; border-radius: 8px;
  font-family: inherit; font-size: 0.95rem; outline: none; transition: all 0.2s;
}
.form-row input[type="text"]:focus,
.form-row textarea:focus { border-color: var(--brand-gradient-start); box-shadow: 0 0 0 3px rgba(15,118,110,0.1); }
.form-row textarea { min-height: 80px; resize: vertical; }

.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.hour-selects { display: flex; align-items: center; gap: 8px; }
.hour-selects select {
  padding: 8px; border: 1px solid #d6d3d1; border-radius: 8px;
  outline: none; font-size: 0.9rem; color: #292524; flex: 1;
}
.sep { color: #a8a29e; font-weight: 700; }
.color-picker-wrapper input[type="color"] {
  width: 100%; height: 38px; padding: 2px; border: 1px solid #d6d3d1; border-radius: 8px; cursor: pointer;
}

.checkbox-list {
  display: flex; flex-wrap: wrap; gap: 8px; max-height: 120px; overflow-y: auto;
  border: 1px solid #f5f0ea; padding: 8px; border-radius: 8px; background: #fafafa;
}
.checkbox-item {
  display: flex; align-items: center; gap: 6px; padding: 4px 8px; background: #fff;
  border: 1px solid #e7e0d7; border-radius: 6px; font-size: 0.85rem; cursor: pointer;
  transition: all 0.1s;
}
.checkbox-item:hover { border-color: #d6d3d1; }

.form-error { color: #ef4444; font-size: 0.85rem; font-weight: 600; background: #fef2f2; padding: 8px; border-radius: 6px; text-align: center; }

.modal-footer {
  padding: 16px 20px; border-top: 1px solid #f5f0ea; background: #fafafa;
  display: flex; justify-content: flex-end; gap: 12px;
}
.btn-cancel {
  background: #fff; border: 1px solid #e7e0d7; color: #57534e; padding: 8px 16px;
  border-radius: 8px; font-weight: 600; cursor: pointer;
}
.btn-cancel:hover { background: #f5f0ea; color: #1c1917; }
.btn-primary {
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end)); border: none; color: #fff; padding: 8px 20px;
  border-radius: 10px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 14px rgba(15,118,110,0.3);
  transition: all 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.btn-primary:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(15,118,110,0.4); }

/* Task Item Clickable */
.task-item.clickable {
  cursor: pointer;
}
.task-info { display: flex; align-items: center; gap: 10px; flex: 1; }
.task-marker { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.task-title { font-weight: 600; color: #292524; font-size: 0.95rem; line-height: 1.4; }

/* Detail Modal Styles */
.detail-card-home .modal-header { background: #fff; padding: 20px 24px; }
.detail-card-home .header-content { display: flex; flex-direction: column; gap: 4px; }
.detail-card-home .modal-subtitle { font-size: 0.85rem; color: #a8a29e; font-weight: 600; text-transform: capitalize; }

.detail-row { display: flex; gap: 16px; margin-bottom: 8px; }
.detail-icon {
  width: 36px; height: 36px; background: #faf8f5; color: #57534e;
  border-radius: 10px; display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.detail-text { display: flex; flex-direction: column; gap: 4px; flex: 1; justify-content: center; }
.detail-text .label { font-size: 0.75rem; font-weight: 700; color: #a8a29e; text-transform: uppercase; letter-spacing: 0.5px; }
.detail-text .value { font-size: 0.95rem; color: #292524; font-weight: 500; }
.detail-text .value.description { line-height: 1.5; color: #44403c; }

.responsibles-list { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 4px; }
.responsible-badge {
  background: #f5f0ea; color: #44403c; font-size: 0.8rem; font-weight: 600;
  padding: 4px 10px; border-radius: 6px; border: 1px solid #e7e0d7;
}

.home-page {
  background:
    radial-gradient(circle at 12% 10%, rgba(15, 118, 110, 0.12), transparent 30%),
    radial-gradient(circle at 84% 18%, rgba(217, 119, 6, 0.14), transparent 24%),
    linear-gradient(145deg, #f7f2ea 0%, #f5efe6 46%, #efe5d8 100%);
}

.home-content {
  width: 100%;
  padding: 18px 22px 24px;
}

.welcome-bar {
  display: grid;
  grid-template-columns: minmax(0, 1.18fr) minmax(340px, 0.9fr);
  gap: 16px;
  align-items: center;
  padding: 18px 22px;
  background:
    linear-gradient(135deg, rgba(255, 252, 247, 0.97) 0%, rgba(247, 241, 232, 0.95) 100%);
  border: 1px solid rgba(201, 182, 159, 0.3);
  border-radius: 26px;
  box-shadow: 0 18px 36px rgba(94, 71, 49, 0.07);
}

.welcome-left {
  align-items: center;
}

.greeting-icon {
  width: 52px;
  height: 52px;
  border-radius: 18px;
  background: linear-gradient(145deg, #0f766e 0%, #115e59 100%);
  color: #fff7ed;
  box-shadow: 0 12px 22px rgba(15, 118, 110, 0.16);
}

.welcome-copy {
  gap: 3px;
}

.welcome-kicker {
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #8b5e3c;
}

.welcome-title {
  font-size: 14px;
  color: #6b5a4a;
}

.welcome-user {
  font-size: clamp(28px, 3.2vw, 38px);
  line-height: 1;
  letter-spacing: -0.04em;
  color: #1f2937;
}

.welcome-subline {
  font-size: 13px;
  font-weight: 600;
  color: #746250;
}

.welcome-stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.welcome-stat {
  min-height: 72px;
  padding: 12px 14px;
  border-radius: 16px;
  background: rgba(255, 251, 245, 0.84);
  border: 1px solid rgba(214, 198, 182, 0.6);
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 6px;
}

.stat-label {
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #9a6f4d;
}

.stat-value {
  font-size: 15px;
  line-height: 1.25;
  color: #32261d;
  font-weight: 700;
}

.stat-time {
  font-variant-numeric: tabular-nums;
  letter-spacing: 0.06em;
}

.stat-meta {
  font-size: 12px;
  color: #8a6d54;
  font-weight: 600;
}

.weather-stat {
  position: relative;
  overflow: hidden;
}

.weather-stat .stat-value,
.weather-stat .stat-meta {
  position: relative;
  z-index: 1;
}

.weather-orb {
  position: absolute;
  right: -10px;
  top: -12px;
  width: 70px;
  height: 70px;
  border-radius: 999px;
  opacity: 0.9;
  filter: blur(0.2px);
}

.weather-stat.summer .weather-orb {
  background:
    radial-gradient(circle at 35% 35%, rgba(255, 253, 229, 0.96) 0%, rgba(245, 158, 11, 0.72) 42%, rgba(245, 158, 11, 0.1) 74%);
}

.weather-stat.spring .weather-orb {
  background:
    radial-gradient(circle at 35% 35%, rgba(236, 253, 245, 0.98) 0%, rgba(52, 211, 153, 0.56) 42%, rgba(52, 211, 153, 0.08) 74%);
}

.weather-stat.autumn .weather-orb {
  background:
    radial-gradient(circle at 35% 35%, rgba(255, 247, 237, 0.98) 0%, rgba(249, 115, 22, 0.58) 42%, rgba(249, 115, 22, 0.08) 74%);
}

.weather-stat.winter .weather-orb,
.weather-stat.night .weather-orb {
  background:
    radial-gradient(circle at 35% 35%, rgba(239, 246, 255, 0.98) 0%, rgba(96, 165, 250, 0.5) 42%, rgba(96, 165, 250, 0.08) 74%);
}

.home-grid {
  grid-template-columns: minmax(0, 1.32fr) minmax(340px, 0.88fr);
  grid-template-areas:
    "calendar tasks"
    "calendar notifications";
  grid-template-rows: auto auto;
  gap: 18px;
  align-items: start;
}

.calendar-card,
.tasks-card,
.notification-card,
.quicknotes-card {
  border-radius: 24px;
  background:
    linear-gradient(180deg, rgba(255, 252, 248, 0.96) 0%, rgba(249, 243, 235, 0.93) 100%);
  border: 1px solid rgba(212, 195, 177, 0.62);
  box-shadow: 0 20px 46px rgba(88, 67, 49, 0.08);
}

.calendar-card { grid-area: calendar; }
.tasks-card { grid-area: tasks; }
.notification-card { grid-area: notifications; }

.card-header {
  padding: 14px 16px;
}

.card-title,
.month-title {
  font-size: 18px;
  line-height: 1.1;
  letter-spacing: -0.03em;
  color: #241a13;
}

.muted {
  color: #9c8369;
}

.calendar {
  padding: 0 14px 14px;
}

.weekdays span {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #9f7a5d;
}

.day {
  min-height: 66px;
  padding: 9px 8px;
  border-radius: 18px;
  border: 1px solid rgba(225, 212, 198, 0.88);
  background: rgba(255, 251, 246, 0.82);
}

.day:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 22px rgba(83, 63, 47, 0.08);
}

.day.today {
  background: linear-gradient(145deg, rgba(15, 118, 110, 0.14), rgba(255, 250, 242, 0.95));
  border-color: rgba(15, 118, 110, 0.28);
}

.num {
  font-size: 15px;
  font-weight: 800;
  color: #2a211a;
}

.dot {
  width: 9px;
  height: 9px;
  box-shadow: 0 0 0 2px rgba(255, 250, 244, 0.84);
}

.more {
  color: #8d6d52;
  font-weight: 700;
}

.task-item,
.notification-item {
  border-radius: 18px;
  background: rgba(255, 251, 246, 0.84);
  border: 1px solid rgba(223, 210, 197, 0.76);
  box-shadow: none;
}

.task-item:hover,
.notification-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 14px 26px rgba(85, 64, 45, 0.07);
}

.tasks-card,
.notification-card {
  min-height: 0;
}

.tasks-card .card-header,
.notification-card .card-header {
  padding-bottom: 10px;
}

.tasks-list,
.notifications-list {
  max-height: 170px;
  overflow-y: auto;
  padding: 0 14px 14px;
}

.empty-state,
.notice.empty-notice {
  margin: 0 14px 14px;
  min-height: 156px;
}

.task-title,
.notification-title .strong,
.notice-title {
  color: #231913;
}

.time,
.notification-meta,
.notice-date,
.sub {
  color: #866a52;
}

.view-all,
.save-status {
  color: #0f766e;
}

.notice.empty-notice,
.empty-state {
  background: rgba(255, 249, 242, 0.72);
  border: 1px dashed rgba(196, 177, 155, 0.7);
  border-radius: 18px;
}

.action-btn,
.add-btn,
.assign-btn,
.today-btn,
.nav-btn {
  border-radius: 12px;
}

.notes-content {
  padding: 0 14px 14px;
}

.quicknotes-card .notes-content {
  background: transparent;
}

.quicknotes-card textarea {
  min-height: 168px;
  border-radius: 18px;
  background:
    linear-gradient(180deg, rgba(255, 253, 250, 0.96) 0%, rgba(248, 241, 232, 0.92) 100%);
  border: 1px solid rgba(210, 192, 174, 0.76);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.8);
}

.quicknotes-card textarea::placeholder {
  color: #aa8c71;
}

.modal-card {
  border-radius: 24px;
  border: 1px solid rgba(216, 197, 177, 0.74);
  background: linear-gradient(180deg, #fffdf9 0%, #f7efe5 100%);
}

.modal-header,
.modal-footer {
  background: rgba(255, 251, 246, 0.8);
}

.btn-primary {
  background: linear-gradient(135deg, #0f766e, #c97316);
  box-shadow: 0 10px 22px rgba(15, 118, 110, 0.24);
}

.detail-card-home .modal-header {
  background: rgba(255, 251, 246, 0.92);
}

@media (max-width: 1200px) {
  .welcome-bar,
  .home-grid {
    grid-template-columns: 1fr;
  }

  .home-grid {
    grid-template-areas:
      "calendar"
      "tasks"
      "notifications";
  }

  .welcome-stats {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 768px) {
  .home-content {
    padding: 18px 16px 28px;
  }

  .welcome-bar {
    gap: 14px;
    border-radius: 22px;
  }

  .welcome-stats {
    grid-template-columns: 1fr;
  }

  .greeting-icon {
    width: 48px;
    height: 48px;
  }

  .welcome-user {
    font-size: 30px;
  }

  .day {
    min-height: 72px;
  }
}
</style>
