<template>
  <div class="admin-audit">
    <div v-if="toast" class="alert" :class="toastClass" role="alert">
      {{ toast.message }}
      <button type="button" class="btn-close float-end" @click="toast = null"></button>
    </div>

    <section class="audit-toolbar">
      <div class="toolbar-copy">
        <span class="eyebrow">Audit trail</span>
        <strong>{{ totalElements }} records found</strong>
      </div>
      <div class="toolbar-actions">
        <label class="page-size">
          <span>Rows</span>
          <select v-model.number="pageSize" class="form-select compact-select">
            <option :value="5">5</option>
            <option :value="10">10</option>
            <option :value="20">20</option>
          </select>
        </label>
        <button class="btn btn-primary" @click="search">Search</button>
        <button class="btn btn-outline-danger" @click="clearHistory">Clear history</button>
      </div>
    </section>

    <section class="filters-panel">
      <div class="section-head">
        <div>
          <span class="eyebrow">Filters</span>
          <h3>Narrow the trail</h3>
        </div>
        <span class="section-note">Use exact IDs when you need a clean trace.</span>
      </div>

      <div class="filters-grid">
        <label class="field">
          <span>From</span>
          <input v-model="filters.fromLocal" type="datetime-local" class="form-control" />
        </label>
        <label class="field">
          <span>To</span>
          <input v-model="filters.toLocal" type="datetime-local" class="form-control" />
        </label>
        <label class="field">
          <span>Actor ID</span>
          <input v-model.number="filters.actorId" type="number" class="form-control" />
        </label>
        <label class="field">
          <span>Action</span>
          <select v-model="filters.action" class="form-select">
            <option value="">All actions</option>
            <option value="USER_CREATE">User create</option>
            <option value="USER_UPDATE">User update</option>
            <option value="PASSWORD_CHANGE">Password change</option>
            <option value="USER_DELETE">User delete</option>
            <option value="GROUP_MEMBER_UPDATE">Member update</option>
            <option value="ACCOUNT_DISABLE">Account disable</option>
          </select>
        </label>
        <label class="field">
          <span>Target type</span>
          <select v-model="filters.targetType" class="form-select">
            <option value="">All targets</option>
            <option value="USER">User</option>
            <option value="GROUP">Group</option>
          </select>
        </label>
        <label class="field">
          <span>Target ID</span>
          <input v-model.number="filters.targetId" type="number" class="form-control" />
        </label>
        <label class="field">
          <span>Result</span>
          <select v-model="filters.success" class="form-select">
            <option value="">All results</option>
            <option value="true">Success</option>
            <option value="false">Failed</option>
          </select>
        </label>
      </div>
    </section>

    <section class="audit-table-panel">
      <div class="section-head table-head">
        <div>
          <span class="eyebrow">Records</span>
          <h3>Activity log</h3>
        </div>
        <span class="section-note">Failed actions need the fastest scan.</span>
      </div>

      <div class="table-responsive">
        <table class="table audit-table align-middle mb-0">
          <thead>
            <tr>
              <th style="width: 190px">Time</th>
              <th>Actor</th>
              <th style="width: 190px">Action</th>
              <th style="width: 150px">Target</th>
              <th>Name</th>
              <th style="width: 110px">Result</th>
              <th style="width: 140px">Details</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7" class="text-center">
                <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>
              </td>
            </tr>

            <tr v-else-if="logs.length === 0">
              <td colspan="7" class="empty-row">
                <strong>No audit records found.</strong>
                <span>Change filters or run a fresh search.</span>
              </td>
            </tr>

            <tr v-for="log in logs" :key="log.id" :class="{ failed: !log.success }">
              <td class="time-cell">{{ formatDate(log.timestamp) }}</td>
              <td>
                <div class="actor-cell">
                  <strong>{{ log.actorUsername || ('ID ' + log.actorId) }}</strong>
                  <small v-if="log.actorId">ID {{ log.actorId }}</small>
                </div>
              </td>
              <td>
                <span class="action-pill">{{ formatAction(log.action) }}</span>
              </td>
              <td>
                <span class="badge bg-light text-dark">{{ formatTargetType(log.targetType) }} #{{ log.targetId || '-' }}</span>
              </td>
              <td class="target-name">{{ log.targetName || 'Not set' }}</td>
              <td>
                <span class="badge" :class="log.success ? 'bg-success' : 'bg-danger'">{{ log.success ? 'Success' : 'Failed' }}</span>
              </td>
              <td class="text-end">
                <button v-if="hasDetails(log.details)" class="btn btn-sm btn-outline-primary" @click="openDetails(log)">
                  View
                </button>
                <span v-else class="muted-dash">None</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <nav v-if="!loading && totalPages > 1" aria-label="Audit pagination" class="audit-pagination">
      <ul class="pagination pagination-sm">
        <li class="page-item" :class="{ disabled: page === 1 }">
          <button class="page-link" @click="goTo(page - 1)" :disabled="page === 1">Previous</button>
        </li>
        <li v-for="p in totalPages" :key="p" class="page-item" :class="{ active: p === page }">
          <button class="page-link" @click="goTo(p)">{{ p }}</button>
        </li>
        <li class="page-item" :class="{ disabled: page === totalPages }">
          <button class="page-link" @click="goTo(page + 1)" :disabled="page === totalPages">Next</button>
        </li>
      </ul>
    </nav>

    <div v-if="detailsModal" class="modal-backdrop" @click.self="closeDetails">
      <div class="modal-card">
        <div class="modal-header">
          <div>
            <span class="eyebrow">Event details</span>
            <h5>{{ formatAction(selectedLog?.action) }}</h5>
          </div>
          <button type="button" class="btn-close" @click="closeDetails"></button>
        </div>
        <div class="modal-body">
          <div class="details-grid" v-if="selectedDetailsEntries.length">
            <div v-for="item in selectedDetailsEntries" :key="item.key" class="detail-item">
              <div class="detail-label">{{ friendlyKey(item.key) }}</div>
              <div class="detail-value">{{ item.value }}</div>
            </div>
          </div>
          <div v-else class="empty-details">
            No additional details to show.
          </div>

          <div class="technical-block">
            <h6>Technical metadata</h6>
            <div class="technical-info">
              <div><strong>Target:</strong> {{ formatTargetType(selectedLog?.targetType) }} #{{ selectedLog?.targetId || '-' }}</div>
              <div><strong>IP:</strong> {{ selectedLog?.ip || 'N/A' }}</div>
              <div><strong>User-Agent:</strong> {{ selectedLog?.userAgent || 'N/A' }}</div>
              <div><strong>Status Code:</strong> {{ selectedLog?.statusCode || '-' }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import { adminGetAuditLogs, adminClearAuditLogs } from '../../services/admin.service.js'

export default {
  name: 'AdminAudit',
  data() {
    return {
      loading: false,
      logs: [],
      page: 1,
      pageSize: 10,
      totalPages: 1,
      totalElements: 0,
      toast: null,
      selectedLog: null,
      detailsModal: false,
      filters: {
        fromLocal: '',
        toLocal: '',
        actorId: '',
        action: '',
        targetType: '',
        targetId: '',
        success: ''
      }
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    toastClass() {
      if (!this.toast) return ''
      return this.toast.type === 'error' ? 'alert-danger' : 'alert-success'
    },
    selectedDetailsEntries() {
      if (!this.selectedLog) return []
      const obj = this.getDetailsObject(this.selectedLog.details)
      if (!obj) return []
      return Object.entries(obj).map(([k, v]) => ({
        key: k,
        value: v === null ? 'null' : (typeof v === 'object' ? JSON.stringify(v) : String(v))
      }))
    }
  },
  watch: {
    pageSize() {
      this.page = 1
      this.search()
    }
  },
  async mounted() {
    await this.search()
  },
  methods: {
    formatDate(iso) {
      try { return new Date(iso).toLocaleString() } catch { return iso }
    },
    formatRole(role) {
      return role === 'SUPER_ADMIN' ? 'Super Admin' : 'User'
    },
    formatAction(a) {
      const map = {
        USER_CREATE: 'User creation',
        USER_UPDATE: 'User update',
        PASSWORD_CHANGE: 'Password change',
        USER_DELETE: 'User deletion',
        GROUP_MEMBER_UPDATE: 'Member update',
        ACCOUNT_DISABLE: 'Account disable'
      }
      return map[a] || a
    },
    formatTargetType(t) {
      const map = { USER: 'User', GROUP: 'Group' }
      return map[t] || t || 'Target'
    },
    friendlyKey(k) {
      if (!k) return ''
      return (k + '').replace(/_/g, ' ').replace(/\s+/g, ' ').trim().replace(/(^|\s)[a-z]/g, s => s.toUpperCase())
    },
    friendlyValue(v) {
      if (typeof v === 'boolean') return v ? 'Yes' : 'No'
      if (Array.isArray(v)) return `[${v.length} items]`
      if (v && typeof v === 'object') return '{...}'
      const s = v == null ? '' : String(v)
      return s.length > 40 ? `${s.slice(0, 37)}...` : s
    },
    getDetailsObject(details) {
      if (!details) return null
      if (typeof details === 'object') return details
      const text = String(details).trim()
      if (!text || text === '-' || text.toLowerCase() === 'null') return null
      try { return JSON.parse(text) } catch { return { text } }
    },
    inlineDetails(details) {
      const obj = this.getDetailsObject(details)
      if (!obj) return []
      const entries = Object.entries(obj)
      return entries.slice(0, 3).map(([k, v]) => ({ k, v }))
    },
    hasDetails(details) {
      return !!this.getDetailsObject(details)
    },
    openDetails(log) {
      this.selectedLog = log
      this.detailsModal = true
    },
    closeDetails() {
      this.detailsModal = false
      this.selectedLog = null
    },
    toIsoOrNull(localStr) {
      if (!localStr) return null
      const d = new Date(localStr)
      if (isNaN(d.getTime())) return null
      return d.toISOString()
    },
    async search() {
      try {
        this.loading = true
        const params = {
          from: this.toIsoOrNull(this.filters.fromLocal),
          to: this.toIsoOrNull(this.filters.toLocal),
          actorId: this.filters.actorId || null,
          action: this.filters.action || null,
          targetType: this.filters.targetType || null,
          targetId: this.filters.targetId || null,
          success: this.filters.success === '' ? null : (this.filters.success === 'true'),
          page: this.page - 1,
          size: this.pageSize
        }
        const res = await adminGetAuditLogs(this.currentUser.id, params)
        const data = res.data || {}
        this.logs = data.content || []
        this.totalPages = data.totalPages || 1
        this.totalElements = data.totalElements || this.logs.length
      } catch (error) {
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Could not load audit'
        this.showToast(msg, 'error')
      } finally {
        this.loading = false
      }
    },
    async clearHistory() {
      if (!confirm('Delete all audit records? This cannot be undone.')) return
      try {
        await adminClearAuditLogs(this.currentUser.id)
        this.showToast('History deleted')
        this.page = 1
        this.search()
      } catch (error) {
        this.showToast('Could not delete history', 'error')
      }
    },
    goTo(p) {
      const newPage = Math.min(Math.max(1, p), this.totalPages)
      if (newPage !== this.page) { this.page = newPage; this.search() }
    },
    showToast(message, type = 'success') {
      this.toast = { message, type }
      setTimeout(() => { this.toast = null }, 3000)
    }
  }
}
</script>

<style scoped>
.admin-audit {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.eyebrow {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #9a6b48;
}

.audit-toolbar,
.filters-panel,
.audit-table-panel {
  border: 1px solid rgba(214, 197, 181, 0.72);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.94) 0%, rgba(248, 241, 233, 0.9) 100%);
  box-shadow: 0 16px 30px rgba(76, 56, 38, 0.05);
}

.audit-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px;
  border-radius: 22px;
}

.toolbar-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.toolbar-copy strong {
  font-size: 20px;
  line-height: 1;
  color: #211913;
}

.toolbar-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 10px;
}

.compact-select {
  width: 130px;
}

.page-size {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #7b6655;
  font-size: 13px;
  font-weight: 700;
}

.filters-panel,
.audit-table-panel {
  border-radius: 24px;
  overflow: hidden;
}

.section-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  border-bottom: 1px solid rgba(214, 197, 181, 0.66);
  background: rgba(244, 237, 228, 0.62);
}

.section-head h3 {
  margin: 3px 0 0;
  font-size: 22px;
  line-height: 1;
  letter-spacing: 0;
  color: #211913;
}

.section-note {
  max-width: 280px;
  color: #7b6655;
  font-size: 13px;
  font-weight: 700;
  text-align: right;
}

.filters-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(150px, 1fr));
  gap: 12px;
  padding: 18px;
}

.field {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.field > span {
  color: #6f5a48;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.audit-table {
  min-width: 980px;
}

.time-cell {
  color: #5f4d3e;
  font-weight: 700;
}

.actor-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.actor-cell strong {
  color: #211913;
}

.actor-cell small {
  color: #7b6655;
  font-weight: 700;
}

.action-pill {
  display: inline-flex;
  align-items: center;
  min-height: 32px;
  padding: 6px 10px;
  border-radius: 999px;
  background: rgba(244, 237, 228, 0.82);
  color: #403329;
  font-weight: 800;
  font-size: 13px;
}

.target-name {
  color: #2b2119;
  font-weight: 700;
}

.failed {
  background: rgba(255, 239, 233, 0.52);
}

.muted-dash {
  color: #8a735f;
  font-weight: 700;
}

.empty-row {
  padding: 32px 18px !important;
  text-align: center;
}

.empty-row strong,
.empty-row span {
  display: block;
}

.empty-row strong {
  color: #251a12;
  font-size: 18px;
}

.empty-row span {
  margin-top: 4px;
  color: #7b6655;
  font-weight: 600;
}

.audit-pagination {
  display: flex;
  justify-content: flex-end;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(42, 30, 20, 0.38);
  backdrop-filter: blur(5px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1050;
}

.modal-card {
  width: min(760px, calc(100vw - 32px));
  max-height: calc(100vh - 48px);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  border-radius: 24px;
  border: 1px solid rgba(214, 197, 181, 0.74);
  background: linear-gradient(180deg, #fffdf8 0%, #f7efe5 100%);
  box-shadow: 0 24px 48px rgba(62, 42, 27, 0.16);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(214, 197, 181, 0.66);
}

.modal-header h5 {
  margin: 3px 0 0;
  color: #211913;
  font-weight: 800;
}

.modal-body {
  padding: 20px;
  overflow: auto;
}

.details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 12px;
}

.detail-item {
  padding: 12px;
  border-radius: 16px;
  border: 1px solid rgba(214, 197, 181, 0.66);
  background: rgba(255, 251, 246, 0.82);
}

.detail-label {
  margin-bottom: 4px;
  color: #6f5a48;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.detail-value {
  color: #211913;
  font-size: 14px;
  font-weight: 700;
  word-break: break-word;
}

.empty-details {
  padding: 28px;
  text-align: center;
  color: #7b6655;
  font-weight: 700;
}

.technical-block {
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid rgba(214, 197, 181, 0.72);
}

.technical-block h6 {
  margin: 0 0 10px;
  color: #6f5a48;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.technical-info {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
  color: #403329;
  font-size: 13px;
}

@media (max-width: 1050px) {
  .filters-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .audit-toolbar,
  .section-head {
    align-items: flex-start;
    flex-direction: column;
  }

  .toolbar-actions,
  .compact-select,
  .page-size,
  .section-note {
    width: 100%;
    text-align: left;
  }

  .filters-grid,
  .technical-info {
    grid-template-columns: 1fr;
  }
}
</style>
