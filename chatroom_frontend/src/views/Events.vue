<template>
  <div class="events-page light">
    <AppDock />
    <main class="content">
      <header class="topbar">
        <div class="left topbar-copy">
          <span class="topbar-kicker">Month board</span>
          <h1 class="title">{{ monthLabel }}</h1>
          <p class="topbar-subtitle">{{ monthEvents.length }} blocks in this view.</p>
        </div>
        <div class="controls gap8-2">
          <button class="nav-btn" @click="prevMonth" aria-label="Previous month">
            <Icon name="chevron-left" :size="18" />
          </button>
          <button class="nav-btn" @click="nextMonth" aria-label="Next month">
            <Icon name="chevron-right" :size="18" />
          </button>
          <button class="primary" @click="goToday">Today</button>
        </div>
      </header>

      <section class="calendar-wrap gap8-2">
        <div class="calendar-column">
          <div class="calendar">
            <div class="weekdays gap8-1">
              <div v-for="d in weekdays" :key="d" class="wd">{{ d }}</div>
            </div>
            <transition name="fade-slide" mode="out-in">
              <div class="days gap8-1" :key="monthLabel">
                <div v-for="n in startOffset" :key="'empty-'+n" class="day empty"></div>
                <div
                  v-for="day in daysInMonth"
                  :key="day"
                  :class="['day', isToday(day) && 'today', isSelected(day) && 'selected']"
                  @click="selectDay(day)"
                  @dblclick="openCreateForm"
                >
                  <div class="day-header">
                    <span class="num">{{ day }}</span>
                  </div>
                  <div class="event-indicators">
                    <div
                      v-for="(ev, i) in eventsForDay(day).slice(0, 3)"
                      :key="i"
                      class="event-indicator"
                      :style="{ backgroundColor: ev.color }"
                      :title="ev.title + ' (' + ev.time + ')'"
                    ></div>
                    <div v-if="eventsForDay(day).length > 3" class="event-indicator-more">
                      +{{ eventsForDay(day).length - 3 }}
                    </div>
                  </div>
                </div>
              </div>
            </transition>
          </div>

          <div class="month-agenda-section">
            <h2 class="section-title">This month</h2>
            <div class="agenda-list">
              <div v-if="monthEvents.length === 0" class="agenda-empty">
                Nothing booked this month.
              </div>
              <div v-else v-for="ev in monthEvents" :key="'m-'+ev.id" :class="['agenda-item', isPastEvent(ev) && 'is-past']" @click="selectDayAndEvent(ev)">
                <div class="agenda-date">
                  <span class="agenda-day">{{ new Date(ev.date).getDate() }}</span>
                  <span class="agenda-weekday">{{ getWeekdayShort(ev.date) }}</span>
                </div>
                <div class="agenda-content">
                  <div class="agenda-marker" :style="{ backgroundColor: ev.color }"></div>
                  <div class="agenda-details">
                    <div class="agenda-title">{{ ev.title }}</div>
                    <div class="agenda-time">{{ ev.time || 'All day' }}</div>
                  </div>
                </div>
                <div class="agenda-meta">
                   <div class="agenda-user" v-if="ev.createdById">
                     <Icon name="user" :size="12" /> {{ usernameById(ev.createdById) }}
                   </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <aside class="sidebar">
          <div class="panel">
            <div class="panel-header-row">
              <div class="panel-copy">
                <h2 class="panel-title">{{ selectedDay ? selectedDayLabel : 'Pick a day' }}</h2>
                <p class="panel-subtitle">{{ filteredEvents.length }} events lined up.</p>
              </div>
              <button class="primary-sm icon-only" @click="openCreateForm" title="New event" v-if="selectedDay">
                <Icon name="plus" :size="16" />
              </button>
            </div>
            
            <ul class="event-list gap8-2">
              <template v-if="loadingEvents">
                <li v-for="n in 5" :key="'sk-'+n" class="event-item skeleton">
                  <div class="event-left">
                    <span class="badge skeleton-badge"></span>
                  </div>
                  <div class="event-info">
                    <div class="event-title skeleton-line" style="width: 50%"></div>
                    <div class="event-time skeleton-line" style="width: 35%; margin-top: 6px"></div>
                  </div>
                </li>
              </template>
              <template v-else>
                <transition-group name="list" tag="div" style="display:contents">
                <li v-for="ev in filteredEvents" :key="ev.id" :class="['event-item', isPastEvent(ev) && 'is-past']" @click="openEventDetails(ev)" style="cursor: pointer">
                  <div class="event-left">
                    <span class="badge" :style="{ background: ev.color }"></span>
                  </div>
                  <div class="event-info">
                    <div class="event-title">{{ ev.title }}</div>
                    <div class="event-time">{{ ev.time }}</div>
                    <div class="event-meta">
                      <span v-if="ev.createdById">Creator: {{ usernameById(ev.createdById) }}</span>
                      <span v-if="(ev.responsibleIds && ev.responsibleIds.length) || (ev.assignedToIds && ev.assignedToIds.length)" style="margin-left: 8px">
                        Assignees: {{ ((ev.responsibleIds || ev.assignedToIds) || []).map(id => usernameById(id)).join(', ') }}
                      </span>
                    </div>
                    <div class="event-desc" v-if="ev.description">{{ ev.description }}</div>
                  </div>
                </li>
                </transition-group>
                <li v-if="filteredEvents.length === 0" class="event-empty-state">
                  <div class="empty-illustration">
                    <Icon name="calendar" :size="48" />
                  </div>
                  <h3 class="empty-title">{{ selectedDay ? 'Quiet day.' : 'No events yet.' }}</h3>
                  <p class="empty-desc" v-if="selectedDay">Nothing booked for this date.</p>
                  <p class="empty-desc" v-else>Pick a day and start a block.</p>
                  <div v-if="selectedDay" style="margin-top: 20px">
                  </div>
                </li>
              </template>
            </ul>
            <div v-if="detailOpen" class="detail-modal">
              <div class="detail-card">
                <div class="detail-header">
                  <div class="detail-title">
                    <span class="badge" :style="{ background: detailEvent.color }"></span>
                    {{ detailEvent.title }}
                  </div>
                  <button class="close" title="Close" @click="closeEventDetails">×</button>
                </div>
                <div class="detail-body">
                  <div class="detail-row"><strong>Date:</strong> {{ (detailEvent && detailEvent.date) || '—' }}</div>
                  <div class="detail-row"><strong>Time:</strong> {{ detailEvent.time || '—' }}</div>
                  <div class="detail-row"><strong>Description:</strong> {{ detailEvent.description || '—' }}</div>
                  <div class="detail-row">
            <strong>Creator:</strong>
            {{ detailEvent.createdBy ? detailEvent.createdBy.username : (detailEvent.createdById ? usernameById(detailEvent.createdById) : '—') }}
          </div>
          <div class="detail-row">
            <strong>Assignees:</strong>
            <template v-if="detailEvent.responsibles && detailEvent.responsibles.length">
              {{ detailEvent.responsibles.map(u => u.username).join(', ') }}
            </template>
            <template v-else-if="detailEvent.responsibleIds && detailEvent.responsibleIds.length">
              {{ detailEvent.responsibleIds.map(id => usernameById(id)).join(', ') }}
            </template>
            <span v-else>—</span>
          </div>
                </div>
                <div class="detail-actions">
                  <button class="danger" :disabled="deleting" @click="removeEvent">{{ deleting ? 'Deleting…' : 'Delete' }}</button>
                  <button class="cancel" :disabled="deleting" @click="closeEventDetails">Close</button>
                </div>
                <div v-if="deleteError" class="form-error">{{ deleteError }}</div>
              </div>
            </div>

            <!-- Create Modal -->
            <transition name="modal">
            <div v-if="createOpen" class="detail-modal" style="z-index: 60;">
              <div class="detail-card create-card">
                <div class="detail-header">
                  <div class="detail-title"><Icon name="plus" :size="20" /> New event</div>
                  <button type="button" class="close" title="Close" @click="cancelCreate">×</button>
                </div>
                <div class="detail-body">
                  <div class="form-info-bar">
                    <div class="info-item">
                        <Icon name="calendar" :size="14" />
                        <span>{{ toISO(year, month, selectedDay || 1) }}</span>
                    </div>
                    <div class="info-item">
                        <Icon name="user" :size="14" />
                        <span>{{ currentUser?.username || '—' }}</span>
                    </div>
                  </div>

                  <div class="form-section">
                    <div class="form-row">
                        <label>Title</label>
                        <div class="input-wrapper">
                            <input type="text" v-model="newEvent.title" placeholder="e.g. Team meeting" autofocus />
                        </div>
                    </div>
                    
                    <div class="form-grid-2">
                         <div class="form-row">
                            <label>Time</label>
                            <div class="time-range">
                                <select v-model="newEvent.startHour">
                                <option :value="null">Start</option>
                                <option v-for="h in hours24" :key="'sh-'+h" :value="h">{{ pad2(h) }}:00</option>
                                </select>
                                <span class="arrow">→</span>
                                <select v-model="newEvent.endHour">
                                <option :value="null">End</option>
                                <option v-for="h in hours24" :key="'eh-'+h" :value="h">{{ pad2(h) }}:00</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-row">
                            <label>Color</label>
                            <div class="color-input-wrapper">
                                <input v-model="newEvent.color" type="color" title="Pick a color" />
                            </div>
                        </div>
                    </div>

                    <div class="form-row">
                        <label>Description</label>
                        <textarea v-model="newEvent.description" placeholder="Add details…"></textarea>
                    </div>

                    <div class="form-row">
                        <label>Participants</label>
                        <div class="users-select-container">
                            <div class="users-list">
                                <label v-for="u in users" :key="u.id" class="user-option" :class="{checked: newEvent.assignedToIds.includes(u.id)}">
                                    <input type="checkbox" :value="u.id" v-model="newEvent.assignedToIds" hidden />
                                    <span class="user-avatar">{{ u.username.charAt(0).toUpperCase() }}</span>
                                    <span class="user-name">{{ u.username }}</span>
                                    <Icon v-if="newEvent.assignedToIds.includes(u.id)" name="check" :size="14" class="check-icon" />
                                </label>
                            </div>
                        </div>
                    </div>
                  </div>
                </div>
                <div class="detail-actions">
                  <button class="cancel" @click="cancelCreate">Cancel</button>
                  <button class="primary" @click="submitCreate">Create Event</button>
                </div>
                <div v-if="createError" class="form-error-banner">
                    <Icon name="alert-circle" :size="16" /> {{ createError }}
                </div>
              </div>
            </div>
            </transition>
          </div>
        </aside>
      </section>
    </main>
  </div>
  
</template>

<script>
import AppDock from '../components/AppDock.vue'
import Icon from '../components/Icon.vue'
import { fetchMonthEvents, createEvent, deleteEvent } from '../services/events.service.js'
import { fetchUsers } from '../services/user.service.js'
import { connectWebSocket, disconnectWebSocket, subscribe } from '../services/websocket.js'
import { mapGetters } from 'vuex'

export default {
  name: 'Events',
  components: { AppDock, Icon },
  data() {
    const now = new Date()
    return {
      cursor: new Date(now.getFullYear(), now.getMonth(), 1),
      selectedDay: now.getDate(),
      events: [],
      loadingEvents: false,
      weekdays: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
      createOpen: false,
      createError: '',
      newEvent: { title: '', description: '', time: '', color: '#0f766e', assignedToIds: [], startHour: null, endHour: null },
      users: [],
      detailOpen: false,
      detailEvent: null,
      deleteError: '',
      deleting: false
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    year() { return this.cursor.getFullYear() },
    month() { return this.cursor.getMonth() },
    daysInMonth() { return new Date(this.year, this.month + 1, 0).getDate() },
    startOffset() {
      // index Monday-based
      const jsDow = new Date(this.year, this.month, 1).getDay() // 0=Sun..6=Sat
      const mondayIndex = (jsDow + 6) % 7
      return mondayIndex
    },
    monthLabel() {
      const s = this.cursor.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
      return s.charAt(0).toUpperCase() + s.slice(1)
    },
    selectedDayLabel() {
      if (!this.selectedDay) return ''
      const d = new Date(this.year, this.month, this.selectedDay)
      return d.toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short' })
    },
    hours24() {
      return Array.from({ length: 24 }, (_, i) => i)
    },
    monthEvents() {
      const ym = `${this.year}-${String(this.month+1).padStart(2,'0')}`
      return this.events
        .filter(e => (e.date || '').startsWith(ym))
        .sort((a,b) => (a.date||'').localeCompare(b.date||''))
    },
    filteredEvents() {
      if (this.selectedDay) {
        const key = this.toISO(this.year, this.month, this.selectedDay)
        return this.events.filter(e => e.date === key)
      }
      return [] // Always empty if no day selected, though selectedDay is init to today
    }
  },
  methods: {
    getWeekdayShort(dateStr) {
        if (!dateStr) return '';
        const d = new Date(dateStr);
        return d.toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase();
    },
    selectDayAndEvent(ev) {
        if (ev.date) {
            const d = new Date(ev.date);
            // Ensure we switch month if needed (though monthEvents only shows current month)
            this.selectedDay = d.getDate();
        }
        this.openEventDetails(ev);
    },
    isPastEvent(ev) {
      if (!ev.date) return false
      const now = new Date()
      const today = this.toISO(now.getFullYear(), now.getMonth(), now.getDate())
      return ev.date < today
    },
    pad2(n) { return String(n).padStart(2,'0') },
    toISO(y,m,d) { return `${y}-${String(m+1).padStart(2,'0')}-${String(d).padStart(2,'0')}` },
    isToday(day) {
      const t = new Date()
      return t.getFullYear()===this.year && t.getMonth()===this.month && t.getDate()===day
    },
    isSelected(day) { return this.selectedDay === day },
    selectDay(day) { 
      // Si ya está seleccionado, solo mantener (para doble clic)
      // Si es nuevo, seleccionar
      this.selectedDay = day 
    },
    clearSelection() {
      this.selectedDay = null
    },
    eventsForDay(day) {
      const key = this.toISO(this.year, this.month, day)
      return this.events.filter(e => e.date === key)
    },
    prevMonth() {
      const m = new Date(this.year, this.month - 1, 1)
      this.cursor = m
      this.selectedDay = 1
    },
    nextMonth() {
      const m = new Date(this.year, this.month + 1, 1)
      this.cursor = m
      this.selectedDay = 1
    },
    goToday() {
      const now = new Date()
      this.cursor = new Date(now.getFullYear(), now.getMonth(), 1)
      this.selectedDay = now.getDate()
    },
    openCreateForm() {
      this.createOpen = true
      this.createError = ''
      if (!this.newEvent.color) this.newEvent.color = '#0f766e'
    },
    cancelCreate() {
      this.createOpen = false
      this.createError = ''
      this.newEvent = { title: '', description: '', time: '', color: '#0f766e', assignedToIds: [], startHour: null, endHour: null }
    },
    async submitCreate() {
      const d = this.selectedDay || 1
      const title = (this.newEvent.title || '').trim()
      if (!title) { this.createError = 'Title is required'; return }
      // Construir la cadena de tiempo a partir de los selects
      let timeStr = null
      const sh = this.newEvent.startHour
      const eh = this.newEvent.endHour
      if (sh != null || eh != null) {
        if (sh == null || eh == null) {
          this.createError = 'Pick start and end time';
          return
        }
        if (Number(eh) < Number(sh)) {
          this.createError = 'End time can\'t be before start';
          return
        }
        timeStr = `${this.pad2(Number(sh))}:00 - ${this.pad2(Number(eh))}:00`
      }
      const payload = {
        title,
        description: (this.newEvent.description || '').trim() || null,
        time: timeStr,
        color: this.newEvent.color || '#0f766e',
        date: this.toISO(this.year, this.month, d),
        createdById: this.currentUser?.id || null,
        responsibleIds: Array.isArray(this.newEvent.assignedToIds) ? this.newEvent.assignedToIds : []
      }
      try {
        const created = await createEvent(payload)
        if (created) {
          await this.loadMonth()
          this.cancelCreate()
        }
      } catch (e) {
        // No crear localmente para evitar confusión entre estado local y backend
        const msg = e?.response?.data?.message || 'Could not save event'
        this.createError = msg
      }
    },
    async loadMonth() {
      this.loadingEvents = true
      try {
        const list = await fetchMonthEvents(this.year, this.month + 1)
        this.events = Array.isArray(list) ? list : []
      } catch (e) {
        console.warn('No se pudieron cargar eventos del backend')
        this.events = []
      } finally {
        this.loadingEvents = false
      }
    },
    async loadUsers() {
      try {
        const res = await fetchUsers()
        // Filtrar para que no salga el SUPER_ADMIN en la lista de asignables
        this.users = (Array.isArray(res.data) ? res.data : []).filter(u => u.role !== 'SUPER_ADMIN')
      } catch (e) {
        console.error(e)
      }
    },
    usernameById(id) {
      const u = this.users.find(x => String(x.id) === String(id))
      return u ? u.username : id
    },
    openEventDetails(ev) {
      this.detailEvent = ev
      this.detailOpen = true
      this.deleteError = ''
    },
    closeEventDetails() {
      this.detailOpen = false
      this.detailEvent = null
      this.deleteError = ''
    },
    async removeEvent() {
      if (!this.detailEvent?.id) return
      this.deleting = true
      this.deleteError = ''
      try {
        await deleteEvent(this.detailEvent.id)
        this.closeEventDetails()
        await this.loadMonth()
      } catch (e) {
        const msg = e?.response?.data?.message || 'Could not delete event'
        this.deleteError = msg
      } finally {
        this.deleting = false
      }
    },
    initWebSocketConnection() {
      if (!this.currentUser) return
      connectWebSocket(window.location.origin + '/ws', this.currentUser.username, null, () => {
        console.log('WebSocket conectado en Events')
        this.subscribeToPublicChannel()
      }, (err) => {
        console.error('Error de WebSocket en Events:', err)
      })
    },
    subscribeToPublicChannel() {
      subscribe('/topic/public', (msg) => {
        if (msg && msg.action === 'user_updated') {
          if (String(msg.userId) === String(this.currentUser.id)) {
            this.$store.commit('auth/SET_USER', { ...this.currentUser, avatarUrl: msg.avatarUrl, username: msg.username })
          }
          if (this.users) {
            this.users = this.users.map(u => {
              if (String(u.id) === String(msg.userId)) {
                return { ...u, avatarUrl: msg.avatarUrl, username: msg.username }
              }
              return u
            })
          }
        }
      })
    },
    handleKeydown(e) {
      if (e.key === 'Escape') {
        if (this.detailOpen) this.closeEventDetails()
        if (this.createOpen) this.cancelCreate()
      }
    }
  },
  async mounted() {
    window.addEventListener('keydown', this.handleKeydown)
    await this.loadMonth()
    await this.loadUsers()
    this.initWebSocketConnection()
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this.handleKeydown)
    disconnectWebSocket()
  },
  watch: {
    month() { this.loadMonth() },
    year() { this.loadMonth() },
    selectedDay() {
      // Reset create form date if open
      if (this.createOpen) {
        this.createError = ''
      }
    }
  }
}
</script>

<style scoped>
.events-page.light { display: flex; min-height: 100vh; background: linear-gradient(135deg, #faf8f5 0%, #f0f4ff 50%, #faf8f5 100%); color: #1c1917; }
.content { flex: 1; padding: 24px 32px; overflow-y: auto; }

/* Transitions */
.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.3s cubic-bezier(0.22, 0.61, 0.36, 1); }
.fade-slide-enter-from { opacity: 0; transform: translateX(10px); }
.fade-slide-leave-to { opacity: 0; transform: translateX(-10px); }

.list-enter-active, .list-leave-active { transition: all 0.3s cubic-bezier(0.22, 0.61, 0.36, 1); }
.list-enter-from, .list-leave-to { opacity: 0; transform: translateX(20px); }

.topbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.title { font-size: 28px; font-weight: 800; color: #1c1917; letter-spacing: -0.5px; }
.controls { display: flex; align-items: center; gap: 12px; }
.nav-btn {
  width: 36px; height: 36px; border-radius: 12px; border: 1px solid #e7e0d7;
  background: #fff; color: #57534e; cursor: pointer; transition: all 0.2s;
  display: flex; align-items: center; justify-content: center;
}
.nav-btn:hover { background: #f5f0ea; color: #1c1917; border-color: #d6d3d1; }
.primary {
  padding: 10px 20px; border-radius: 12px; border: none;
  background: linear-gradient(135deg, #0f766e 0%, #ea580c 100%);
  color: #fff; font-weight: 600; cursor: pointer;
  box-shadow: 0 4px 14px rgba(15,118,110, 0.3);
  transition: all 0.2s;
  display: flex; align-items: center; justify-content: center;
}
.primary.full-width { width: 100%; }
.primary:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(15,118,110, 0.35); }

.calendar-wrap { display: grid; grid-template-columns: 1fr 360px; gap: 24px; }
.calendar-column { display: flex; flex-direction: column; gap: 24px; }
.calendar {
  background: #ffffff; border-radius: 24px; padding: 24px;
  box-shadow: 0 10px 30px -5px rgba(15,118,110,0.06), 0 4px 6px rgba(0,0,0,0.02);
  border: 1px solid rgba(15,118,110,0.04);
}

.month-agenda-section {
  background: #ffffff; border-radius: 24px; padding: 24px;
  box-shadow: 0 10px 30px -5px rgba(15,118,110,0.06);
  border: 1px solid rgba(15,118,110,0.04);
}
.section-title { font-size: 1.2rem; font-weight: 800; color: #1c1917; margin-bottom: 20px; }

.agenda-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; }
.agenda-empty { color: #a8a29e; font-style: italic; grid-column: 1/-1; text-align: center; padding: 20px; }

.agenda-item {
  display: flex; align-items: center; gap: 16px;
  background: #fff; border: 1px solid #f5f0ea; border-radius: 16px;
  padding: 16px; cursor: pointer; transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.02);
}
.agenda-item:hover {
  transform: translateY(-2px); border-color: rgba(15,118,110,0.2);
  box-shadow: 0 8px 20px -4px rgba(15,118,110,0.1);
}

.agenda-date {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  width: 50px; height: 50px; background: #faf8f5; border-radius: 12px;
  border: 1px solid #e7e0d7; flex-shrink: 0;
}
.agenda-day { font-size: 1.2rem; font-weight: 800; color: #1c1917; line-height: 1; }
.agenda-weekday { font-size: 0.65rem; font-weight: 700; color: #57534e; margin-top: 2px; }

.agenda-content { flex: 1; display: flex; align-items: flex-start; gap: 10px; overflow: hidden; }
.agenda-marker { width: 4px; height: 32px; border-radius: 4px; flex-shrink: 0; margin-top: 4px; }
.agenda-details { display: flex; flex-direction: column; overflow: hidden; }
.agenda-title { font-weight: 700; color: #292524; font-size: 0.95rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.agenda-time { font-size: 0.8rem; color: #a8a29e; margin-top: 2px; }

.agenda-meta { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; flex-shrink: 0; }
.agenda-user { display: flex; align-items: center; gap: 4px; font-size: 0.75rem; color: #57534e; background: #f5f0ea; padding: 4px 8px; border-radius: 6px; }

.weekdays { display: grid; grid-template-columns: repeat(7, 1fr); margin-bottom: 16px; }
.wd {
  padding: 10px; text-align: center; color: #a8a29e; font-weight: 700; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.5px;
}

.days { display: grid; grid-template-columns: repeat(7, 1fr); gap: 8px; }
.day {
  background: #fff; border: 1px solid #f5f0ea; border-radius: 16px;
  padding: 10px; min-height: 110px; position: relative;
  transition: all 0.25s cubic-bezier(0.2, 0.8, 0.2, 1);
  cursor: pointer; display: flex; flex-direction: column;
  box-shadow: 0 2px 4px rgba(0,0,0,0.02);
}
.day:hover {
  border-color: #0f766e; transform: translateY(-4px);
  box-shadow: 0 12px 28px -10px rgba(15,118,110, 0.18);
  z-index: 10;
}
.day.today {
  background: linear-gradient(135deg, rgba(15,118,110,0.04), rgba(6,182,212,0.04));
  border-color: #0f766e;
  box-shadow: inset 0 0 0 1px #0f766e, 0 4px 12px rgba(15,118,110,0.08);
}
.day.today .num {
  background: linear-gradient(135deg, #0f766e 0%, #ea580c 100%);
  color: white; width: 28px; height: 28px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 2px 8px rgba(15,118,110,0.35);
}
.day.selected {
  border-color: #0f766e; background: #e6f4ee;
  box-shadow: inset 0 0 0 1px #0f766e;
}
.day.empty { visibility: hidden; pointer-events: none; }

.day-header { display: flex; justify-content: flex-end; margin-bottom: 6px; }
.num { font-weight: 700; color: #44403c; font-size: 0.95rem; transition: color 0.2s; padding: 4px; }

.event-title { font-weight: 700; color: #1c1917; font-size: 0.95rem; margin-bottom: 2px; }
.event-time { font-size: 0.8rem; color: #57534e; font-weight: 500; }
.event-meta { font-size: 0.75rem; color: #a8a29e; margin-top: 4px; }
.event-desc { font-size: 0.8rem; color: #57534e; margin-top: 6px; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.event-indicators { display: flex; flex-direction: column; gap: 3px; margin-top: auto; padding-top: 4px; }
.event-indicator { 
  height: 6px; border-radius: 4px; width: 100%; 
  opacity: 0.85; transition: all 0.2s;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}
.event-indicator:hover { opacity: 1; transform: scaleX(1.02); }
.event-indicator-more { 
  font-size: 10px; color: #57534e; font-weight: 700; text-align: right; 
  background: rgba(241, 245, 249, 0.8); padding: 1px 4px; border-radius: 4px; align-self: flex-end;
}

.sidebar {
  background: #ffffff; border-radius: 24px; padding: 24px;
  box-shadow: 0 10px 30px -5px rgba(15,118,110,0.06);
  border: 1px solid rgba(15,118,110,0.04);
  display: flex; flex-direction: column;
}
.panel-header-row {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;
}
.panel-title { font-size: 20px; font-weight: 800; color: #1c1917; margin: 0; letter-spacing: -0.5px; }
.text-btn { background: none; border: none; color: #0f766e; font-weight: 600; cursor: pointer; font-size: 0.9rem; transition: color 0.2s; }
.text-btn:hover { color: #0f766e; text-decoration: none; }
.text-btn-primary {
  background: none; border: 2px solid #0f766e; color: #0f766e;
  font-weight: 700; cursor: pointer; font-size: 0.9rem;
  padding: 6px 12px; border-radius: 8px; transition: all 0.2s;
}
.text-btn-primary:hover { background: #0f766e; color: #fff; }

.event-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 16px; overflow-y: auto; max-height: calc(100vh - 200px); padding-right: 4px; }
.event-item {
  display: flex; align-items: flex-start; gap: 16px;
  background: #fff; border: 1px solid #f5f0ea; border-radius: 16px;
  padding: 16px; transition: all 0.25s cubic-bezier(0.22, 0.61, 0.36, 1); position: relative; overflow: hidden;
  box-shadow: 0 2px 5px rgba(0,0,0,0.02);
}
.event-item:hover {
  transform: translateY(-3px) scale(1.01);
  box-shadow: 0 12px 24px -8px rgba(15,118,110,0.12);
  border-color: rgba(15,118,110,0.2);
}
.event-left { display: none; } 
.event-item::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 5px;
  background: var(--event-color, #0f766e);
}

.event-empty-state {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 40px 24px; text-align: center;
  background: #faf8f5; border-radius: 20px; border: 2px dashed #e7e0d7;
  color: #57534e; margin-top: 16px;
}
.empty-illustration {
  color: #d6d3d1; margin-bottom: 16px;
  background: #fff; padding: 20px; border-radius: 50%;
  box-shadow: 0 8px 16px rgba(0,0,0,0.03);
}
.empty-title { font-size: 1.1rem; font-weight: 700; color: #292524; margin: 0 0 8px; }
.empty-desc { font-size: 0.9rem; color: #a8a29e; margin: 0; max-width: 250px; line-height: 1.5; }
.primary-sm {
  padding: 8px 16px; border-radius: 10px; border: none;
  background: linear-gradient(135deg, #0f766e, #ea580c); color: #fff; font-weight: 600; cursor: pointer; font-size: 0.85rem;
  display: flex; align-items: center; gap: 8px;
  transition: all 0.2s;
  box-shadow: 0 4px 14px rgba(15,118,110, 0.25);
}
.primary-sm:hover { background: linear-gradient(135deg, #0f766e, #ea580c); transform: translateY(-1px); box-shadow: 0 6px 18px rgba(15,118,110,0.35); }
.btn-create-empty {
  padding: 8px 16px; border-radius: 10px; border: 1px solid #d6d3d1;
  background: #fff; color: #44403c; font-weight: 600; cursor: pointer; font-size: 0.85rem;
  display: flex; align-items: center; gap: 8px;
  transition: all 0.2s;
}
.btn-create-empty:hover { border-color: #0f766e; color: #0f766e; background: #fefeff; }

/* Form Styles */
.create-card { max-width: 500px; }

.form-header { margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #f5f0ea; }
.form-row input, .form-row textarea, select {
  border: 1px solid #d6d3d1; background: #faf8f5;
  transition: all 0.2s;
  width: 100%; padding: 8px 12px; border-radius: 8px; font-size: 0.9rem;
}
.form-row input:focus, .form-row textarea:focus, select:focus {
  background: #fff; border-color: #0f766e; box-shadow: 0 0 0 3px rgba(15,118,110, 0.1); outline: none;
}

/* Detail Modal */
.detail-modal {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(15, 23, 42, 0.5); backdrop-filter: blur(6px);
  display: flex; align-items: center; justify-content: center; z-index: 50;
  animation: fadeIn 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.detail-card {
  background: #fff; width: 90%; max-width: 450px;
  border-radius: 20px; box-shadow: 0 25px 60px -12px rgba(0, 0, 0, 0.25);
  overflow: hidden; animation: scaleIn 0.25s cubic-bezier(0.22, 0.61, 0.36, 1);
  border: 1px solid rgba(255,255,255,0.5);
}
.detail-header {
  padding: 20px 24px; border-bottom: 1px solid #f5f0ea;
  display: flex; justify-content: space-between; align-items: center;
  background: #faf8f5;
}
.detail-title { font-size: 1.2rem; font-weight: 800; color: #1c1917; display: flex; align-items: center; gap: 12px; }
.detail-body { padding: 24px; }
.detail-row { margin-bottom: 12px; font-size: 0.95rem; color: #292524; }
.detail-row strong { color: #1c1917; font-weight: 600; margin-right: 6px; }
.detail-actions {
  padding: 16px 24px; background: #faf8f5; border-top: 1px solid #f5f0ea;
  display: flex; justify-content: flex-end; gap: 12px;
}
.danger { background: #fee2e2; color: #ef4444; border: none; padding: 8px 16px; border-radius: 8px; font-weight: 600; cursor: pointer; transition: background 0.2s; }
.danger:hover { background: #fecaca; }
.cancel { background: #fff; border: 1px solid #d6d3d1; padding: 8px 16px; border-radius: 8px; font-weight: 600; cursor: pointer; transition: background 0.2s; }
.cancel:hover { background: #f5f0ea; }

/* Skeleton */
.skeleton-badge { background: #e7e0d7 !important; }
.skeleton-line { background: linear-gradient(90deg, #f5f0ea, #e7e0d7, #f5f0ea); background-size: 200% 100%; animation: shimmer 1.5s infinite; }

/* Scrollbars */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #d6d3d1; border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #a8a29e; }

@media (max-width: 1024px) {
  .calendar-wrap { grid-template-columns: 1fr; }
  .sidebar { order: 2; }
}

/* Modal Transition */
.modal-enter-active, .modal-leave-active { transition: opacity 0.3s cubic-bezier(0.22, 0.61, 0.36, 1); }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-active .detail-card, .modal-leave-active .detail-card { transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); }
.modal-enter-from .detail-card, .modal-leave-to .detail-card { transform: scale(0.95) translateY(10px); }

/* New Form Styles */
.detail-modal {
  backdrop-filter: blur(4px);
  background: rgba(15, 23, 42, 0.6); /* Darker overlay for focus */
}

.create-card {
  max-width: 520px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  border: 1px solid rgba(255,255,255,0.5); /* Glass border effect */
}

.form-info-bar {
  display: flex; gap: 16px; background: #f5f0ea; padding: 10px 16px; border-radius: 8px; margin-bottom: 20px;
  border: 1px solid #e7e0d7;
}
.info-item { display: flex; align-items: center; gap: 6px; color: #57534e; font-size: 0.85rem; font-weight: 600; }

.form-section { display: flex; flex-direction: column; gap: 18px; }

.input-wrapper { position: relative; }
.form-row input[type="text"] {
  width: 100%; padding: 12px 16px; border: 1px solid #d6d3d1; border-radius: 10px;
  font-size: 1rem; transition: all 0.2s; background: #fcfcfc;
}
.form-row input[type="text"]:focus { 
  border-color: #0f766e; background: #fff;
  box-shadow: 0 0 0 4px rgba(15,118,110,0.1); outline: none; 
}

.form-grid-2 { display: grid; grid-template-columns: 1fr 140px; gap: 16px; }

.time-range { display: flex; align-items: center; gap: 8px; background: #fcfcfc; border: 1px solid #d6d3d1; padding: 4px 8px; border-radius: 10px; }
.time-range:focus-within { border-color: #0f766e; box-shadow: 0 0 0 4px rgba(15,118,110,0.1); }
.time-range select { 
  flex: 1; min-width: 0; padding: 8px 4px; border-radius: 6px; border: none; background: transparent; font-weight: 500; color: #292524;
  cursor: pointer;
}
.time-range select:focus { outline: none; }
.arrow { color: #a8a29e; font-weight: bold; font-size: 0.9rem; }

.color-input-wrapper { 
  display: flex; align-items: center; height: 42px; 
  border: 1px solid #d6d3d1; border-radius: 10px; padding: 4px; background: #fff;
  transition: all 0.2s;
}
.color-input-wrapper:hover { border-color: #a8a29e; }
.color-input-wrapper input[type="color"] { 
  -webkit-appearance: none; border: none; width: 100%; height: 100%; padding: 0; 
  border-radius: 6px; overflow: hidden; cursor: pointer; 
}
.color-input-wrapper input[type="color"]::-webkit-color-swatch-wrapper { padding: 0; }
.color-input-wrapper input[type="color"]::-webkit-color-swatch { border: none; }

.form-row textarea {
    width: 100%; padding: 12px 16px; border: 1px solid #d6d3d1; border-radius: 10px;
    font-size: 0.95rem; transition: all 0.2s; background: #fcfcfc; min-height: 80px; resize: vertical; font-family: inherit;
}
.form-row textarea:focus {
    border-color: #0f766e; background: #fff;
    box-shadow: 0 0 0 4px rgba(15,118,110,0.1); outline: none;
}

.users-select-container {
  border: 1px solid #e7e0d7; border-radius: 10px; padding: 6px; max-height: 150px; overflow-y: auto; background: #fff;
}
.users-list { display: flex; flex-direction: column; gap: 2px; }
.user-option {
  display: flex; align-items: center; gap: 12px; padding: 8px 12px; border-radius: 8px; cursor: pointer; transition: all 0.2s;
  user-select: none;
}
.user-option:hover { background: #faf8f5; }
.user-option.checked { background: #e6f4ee; }
.user-avatar {
  width: 28px; height: 28px; background: #d6d3d1; color: #fff; border-radius: 50%;
  display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 700;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.user-option.checked .user-avatar { background: #0f766e; }
.user-name { font-size: 0.95rem; flex: 1; color: #292524; font-weight: 500; }
.check-icon { color: #0f766e; }

.form-error-banner {
  margin: 0 24px 16px; background: #fef2f2; color: #ef4444; padding: 12px 16px; border-radius: 8px;
  display: flex; align-items: center; gap: 10px; font-size: 0.9rem; border: 1px solid #fecaca;
}

.is-past {
  opacity: 0.6;
}
.is-past .event-title,
.is-past .event-time,
.is-past .agenda-title,
.is-past .agenda-time,
.is-past .agenda-day {
  text-decoration: line-through;
}
.is-past:hover {
  opacity: 0.8;
}

.events-page.light {
  background:
    radial-gradient(circle at 14% 12%, rgba(15, 118, 110, 0.08), transparent 26%),
    radial-gradient(circle at 88% 10%, rgba(234, 88, 12, 0.08), transparent 22%),
    linear-gradient(145deg, #f7f2ea 0%, #f5efe6 48%, #efe6da 100%);
  color: #221912;
}

.content {
  padding: 20px 24px 28px;
}

.topbar {
  align-items: flex-end;
  margin-bottom: 18px;
}

.topbar-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.topbar-kicker {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #9a6b48;
}

.title {
  font-size: 34px;
  line-height: 0.98;
  letter-spacing: -0.04em;
  color: #201812;
}

.topbar-subtitle {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #7a6653;
}

.controls {
  gap: 10px;
}

.nav-btn,
.primary {
  border-radius: 14px;
}

.calendar-wrap {
  grid-template-columns: minmax(0, 1.25fr) minmax(330px, 0.9fr);
  gap: 18px;
  align-items: start;
}

.calendar-column {
  gap: 18px;
}

.calendar,
.month-agenda-section,
.sidebar {
  border-radius: 26px;
  background:
    linear-gradient(180deg, rgba(255, 252, 248, 0.97) 0%, rgba(249, 243, 235, 0.94) 100%);
  border: 1px solid rgba(212, 195, 177, 0.62);
  box-shadow: 0 20px 46px rgba(88, 67, 49, 0.08);
}

.calendar {
  padding: 18px;
}

.month-agenda-section,
.sidebar {
  padding: 18px;
}

.section-title,
.panel-title {
  font-size: 21px;
  line-height: 1.05;
  letter-spacing: -0.03em;
  color: #211913;
}

.panel-header-row {
  margin-bottom: 16px;
}

.panel-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.panel-subtitle {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #856d58;
}

.weekdays {
  margin-bottom: 12px;
}

.wd {
  padding: 8px 6px;
  font-size: 11px;
  letter-spacing: 0.14em;
  color: #9d7a5c;
}

.day {
  min-height: 82px;
  padding: 10px 8px;
  border-radius: 18px;
  border: 1px solid rgba(225, 212, 198, 0.88);
  background: rgba(255, 251, 246, 0.82);
  box-shadow: none;
}

.day:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 22px rgba(83, 63, 47, 0.08);
  border-color: rgba(15, 118, 110, 0.24);
}

.day.today {
  background: linear-gradient(145deg, rgba(15, 118, 110, 0.12), rgba(255, 250, 242, 0.94));
  box-shadow: inset 0 0 0 1px rgba(15, 118, 110, 0.3);
}

.day.selected {
  background: linear-gradient(145deg, rgba(15, 118, 110, 0.16), rgba(250, 247, 242, 0.98));
  border-color: rgba(15, 118, 110, 0.3);
}

.day-header {
  margin-bottom: 8px;
}

.num {
  font-size: 15px;
  color: #2b2119;
}

.event-indicators {
  gap: 4px;
}

.event-indicator {
  height: 7px;
  border-radius: 999px;
}

.event-indicator-more {
  font-size: 10px;
  color: #806651;
  background: rgba(243, 234, 224, 0.82);
}

.agenda-list {
  grid-template-columns: 1fr;
  gap: 12px;
}

.agenda-item {
  border-radius: 18px;
  border-color: rgba(223, 210, 197, 0.76);
  box-shadow: none;
  background: rgba(255, 251, 246, 0.84);
}

.agenda-date {
  width: 54px;
  height: 54px;
  border-radius: 14px;
  background: rgba(255, 249, 242, 0.92);
}

.agenda-day {
  font-size: 20px;
}

.agenda-weekday {
  font-size: 10px;
  letter-spacing: 0.08em;
  color: #8a715b;
}

.agenda-title,
.event-title,
.detail-title {
  color: #231912;
}

.agenda-time,
.event-time,
.event-meta,
.empty-desc {
  color: #7d6652;
}

.sidebar {
  gap: 0;
}

.event-list {
  gap: 12px;
  max-height: calc(100vh - 210px);
  padding-right: 2px;
}

.event-item {
  gap: 12px;
  padding: 14px 14px 14px 18px;
  border-radius: 18px;
  border-color: rgba(223, 210, 197, 0.76);
  box-shadow: none;
  background: rgba(255, 251, 246, 0.84);
}

.event-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 14px 26px rgba(85, 64, 45, 0.07);
}

.event-item::before {
  width: 4px;
}

.event-empty-state {
  margin-top: 8px;
  padding: 32px 18px;
  border-radius: 18px;
  background: rgba(255, 249, 242, 0.72);
}

.primary-sm {
  border-radius: 12px;
}

.detail-card {
  border-radius: 24px;
  background: linear-gradient(180deg, #fffdf9 0%, #f7efe5 100%);
  border: 1px solid rgba(216, 197, 177, 0.74);
}

.detail-header,
.detail-actions {
  background: rgba(255, 251, 246, 0.82);
}

.cancel {
  border-radius: 10px;
}

.danger,
.primary-sm,
.primary {
  box-shadow: 0 10px 22px rgba(15, 118, 110, 0.18);
}

@media (max-width: 1024px) {
  .content {
    padding: 18px 16px 24px;
  }

  .calendar-wrap {
    grid-template-columns: 1fr;
  }
}
</style>
