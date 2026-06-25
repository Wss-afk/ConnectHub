<template>
  <div class="admin-audit">
    <div v-if="toast" class="alert" :class="toastClass" role="alert">
      {{ toast.message }}
      <button type="button" class="btn-close float-end" @click="toast = null"></button>
    </div>

    <div class="filters-card d-flex flex-wrap gap-2 align-items-end">
      <div>
        <label class="form-label">From</label>
        <input v-model="filters.fromLocal" type="datetime-local" class="form-control" style="max-width:220px" />
      </div>
      <div>
        <label class="form-label">To</label>
        <input v-model="filters.toLocal" type="datetime-local" class="form-control" style="max-width:220px" />
      </div>
      <div>
        <label class="form-label">Actor ID</label>
        <input v-model.number="filters.actorId" type="number" class="form-control" style="max-width:140px" />
      </div>
      <div>
        <label class="form-label">Action</label>
        <select v-model="filters.action" class="form-select" style="max-width:200px">
          <option value="">All</option>
          <option value="USER_CREATE">USER_CREATE</option>
          <option value="USER_UPDATE">USER_UPDATE</option>
          <option value="PASSWORD_CHANGE">PASSWORD_CHANGE</option>
          <option value="USER_DELETE">USER_DELETE</option>
          <option value="GROUP_MEMBER_UPDATE">GROUP_MEMBER_UPDATE</option>
          <option value="ACCOUNT_DISABLE">ACCOUNT_DISABLE</option>
        </select>
      </div>
      <div>
        <label class="form-label">Target type</label>
        <select v-model="filters.targetType" class="form-select" style="max-width:160px">
          <option value="">All</option>
          <option value="USER">USER</option>
          <option value="GROUP">GROUP</option>
        </select>
      </div>
      <div>
        <label class="form-label">Target ID</label>
        <input v-model.number="filters.targetId" type="number" class="form-control" style="max-width:140px" />
      </div>
      <div>
        <label class="form-label">Success</label>
        <select v-model="filters.success" class="form-select" style="max-width:140px">
          <option value="">All</option>
          <option value="true">Success</option>
          <option value="false">Error</option>
        </select>
      </div>
      <div class="ms-auto d-flex align-items-end gap-2">
        <div>
          <label class="form-label">Page size</label>
          <select v-model.number="pageSize" class="form-select" style="width:100px">
            <option :value="5">5</option>
            <option :value="10">10</option>
            <option :value="20">20</option>
          </select>
        </div>
        <button class="btn btn-primary" @click="search">Search</button>
        <button class="btn btn-outline-danger" @click="clearHistory">Clear History</button>
      </div>
    </div>

    <div class="table-card">
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table align-middle mb-0">
            <thead>
              <tr>
                <th style="width:180px">Date</th>
                <th>Actor</th>
                <th style="width:200px">Action</th>
                <th style="width:120px">Target</th>
                <th>Name</th>
                <th style="width:90px">Success</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="7" class="text-center">
                  <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>
                </td>
              </tr>
              <tr v-for="log in logs" :key="log.id">
                <td>{{ formatDate(log.timestamp) }}</td>
                <td>
                  <div class="d-flex flex-column">
                    <span>{{ log.actorUsername || ('ID ' + log.actorId) }}</span>
                    <small v-if="log.actorId" class="text-muted">ID {{ log.actorId }}</small>
                  </div>
                </td>
                <td>{{ formatAction(log.action) }}</td>
                <td><span class="badge bg-light text-dark">{{ formatTargetType(log.targetType) }}</span></td>
                <td>{{ log.targetName }}</td>
                <td>
                  <span class="badge" :class="log.success ? 'bg-success' : 'bg-danger'">{{ log.success ? 'Yes' : 'No' }}</span>
                </td>
                <td class="text-end">
                  <button v-if="hasDetails(log.details)" class="btn btn-sm btn-outline-primary py-1 px-3" style="border-radius:20px; font-size:0.8rem" @click="openDetails(log)">
                    View details
                  </button>
                  <span v-else class="text-muted small">—</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <nav v-if="!loading && totalPages > 1" aria-label="Audit pagination" class="mt-2">
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
    
    <!-- Modal Detalles -->
    <div v-if="detailsModal" class="modal-backdrop" @click.self="closeDetails">
      <div class="modal-card">
        <div class="modal-header">
          <div class="d-flex flex-column">
            <span>Event details</span>
            <small class="text-muted fw-normal mt-1">{{ formatAction(selectedLog?.action) }}</small>
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
          <div v-else class="text-muted text-center py-4">
            No additional details to show.
          </div>
          
          <div class="mt-4 pt-3 border-top">
            <h6 class="text-muted mb-2" style="font-size:0.8rem; text-transform:uppercase; letter-spacing:0.5px">Technical Metadata</h6>
            <div class="technical-info">
              <div><strong>Target:</strong> {{ formatTargetType(selectedLog?.targetType) }} #{{ selectedLog?.targetId }}</div>
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
    pageSize() { this.page = 1; this.search() }
  },
  async mounted() {
    await this.search()
  },
  methods: {
    formatDate(iso) {
      try { return new Date(iso).toLocaleString() } catch { return iso }
    },
    formatRole(role) {
      // Unificar roles: excepto SUPER_ADMIN, todo se muestra como Usuario
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
      return map[t] || t
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
      return s.length > 40 ? s.slice(0, 37) + '…' : s
    },
    getDetailsObject(details) {
      if (!details) return null
      if (typeof details === 'object') return details
      const text = String(details).trim()
      if (!text || text === '-' || text.toLowerCase() === 'null') return null
      try { return JSON.parse(text) } catch { return { texto: text } }
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
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Error loading audit'
        this.showToast(msg, 'error')
      } finally {
        this.loading = false
      }
    },
    async clearHistory() {
      if (!confirm('⚠️ Are you sure? This will delete ALL audit records.\n\nThis action cannot be undone.')) return
      try {
        await adminClearAuditLogs(this.currentUser.id)
        this.showToast('History deleted successfully')
        this.page = 1
        this.search()
      } catch (error) {
        this.showToast('Error deleting history', 'error')
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
.admin-audit { padding: 16px; max-width: 1400px; margin: 0 auto; }
.gap-2 { gap: 12px; }
.text-truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* Filtros más limpios */
.filters-card {
  background: linear-gradient(135deg, #ffffff 0%, #faf8f5 100%); border-radius: 16px; padding: 20px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.04); margin-bottom: 20px;
  border: 1px solid rgba(15,118,110,0.08);
}
.form-label { font-weight: 600; color: #57534e; font-size: 0.85rem; margin-bottom: 4px; }
.form-control {
  border-radius: 8px; border: 1px solid #e7e0d7; font-size: 0.9rem; padding: 8px 12px;
  background-color: #fff;
}
.form-select {
  border-radius: 8px; border: 1px solid #e7e0d7; font-size: 0.9rem;
  padding: 8px 36px 8px 12px; /* Extra right padding for arrow */
  background-color: #fff;
  line-height: 1.5;
}
.form-control:focus, .form-select:focus {
  border-color: #0f766e; box-shadow: 0 0 0 3px rgba(15,118,110,0.1);
}

/* Tabla moderna */
.table-card {
  background: #fff; border-radius: 16px; overflow: hidden;
  box-shadow: 0 4px 16px rgba(0,0,0,0.05); border: 1px solid rgba(15,118,110,0.06);
}
.table { margin-bottom: 0; }
.table thead th {
  background: #faf8f5; color: #44403c; font-weight: 700; font-size: 0.85rem;
  text-transform: uppercase; letter-spacing: 0.5px; padding: 14px 16px; border-bottom: 1px solid #e7e0d7;
}
.table tbody td {
  padding: 14px 16px; color: #292524; font-size: 0.9rem; border-bottom: 1px solid #f5f0ea;
}
.table tbody tr:last-child td { border-bottom: none; }
.table tbody tr:hover { background-color: #faf8f5; }

/* Badges */
.badge { padding: 5px 10px; border-radius: 6px; font-weight: 600; font-size: 0.75rem; letter-spacing: 0.3px; }
.bg-success { background: #dcfce7 !important; color: #166534; }
.bg-danger { background: #fee2e2 !important; color: #991b1b; }
.bg-light { background: #f5f0ea !important; color: #44403c; border: 1px solid #e2e8f0; }
.bg-secondary { background: #f3f4f6 !important; color: #4b5563; border: 1px solid #e5e7eb; }

/* Modal */
.modal-backdrop {
  position: fixed; inset: 0; background: rgba(0,0,0,.4); backdrop-filter: blur(2px);
  display: flex; align-items: center; justify-content: center; z-index: 1050;
}
.modal-card {
  background: #fff; border-radius: 16px; width: min(700px, 90vw);
  box-shadow: 0 25px 50px -12px rgba(0,0,0,0.2); overflow: hidden;
  animation: modalIn 0.2s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes modalIn { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }
.modal-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 20px; border-bottom: 1px solid #f5f0ea; background: #fff;
}
.modal-header span { font-weight: 700; color: #1c1917; font-size: 1.1rem; }
.modal-body { padding: 24px; max-height: 70vh; overflow-y: auto; background: #fff; }
.details-grid {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px;
}
.detail-item {
  background: #faf8f5; padding: 12px; border-radius: 8px; border: 1px solid #e7e0d7;
}
.detail-label {
  font-size: 0.75rem; text-transform: uppercase; color: #57534e; font-weight: 700; letter-spacing: 0.5px; margin-bottom: 4px;
}
.detail-value {
  font-size: 0.9rem; color: #1c1917; word-break: break-word; font-family: 'DM Sans', sans-serif;
}
.technical-info {
  display: grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size: 0.85rem; color: #44403c;
}
</style>