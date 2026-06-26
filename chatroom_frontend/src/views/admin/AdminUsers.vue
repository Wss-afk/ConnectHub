<template>
  <div class="admin-users">
    <section class="users-toolbar">
      <div class="toolbar-copy">
        <span class="eyebrow">Directory</span>
        <strong>{{ filteredUsers.length }} users in view</strong>
      </div>
      <div class="toolbar-controls">
        <input v-model="search" class="form-control search-input" placeholder="Search users" />
        <select v-model="roleFilter" class="form-select compact-select">
          <option value="">All roles</option>
          <option value="USER">User</option>
        </select>
        <label class="page-size">
          <span>Rows</span>
          <select v-model.number="pageSize" class="form-select compact-select">
            <option :value="5">5</option>
            <option :value="10">10</option>
            <option :value="20">20</option>
          </select>
        </label>
      </div>
    </section>

    <div v-if="toast" class="alert" :class="toastClass" role="alert">
      {{ toast.message }}
      <button type="button" class="btn-close float-end" @click="toast = null"></button>
    </div>

    <section class="create-user-panel">
      <div class="section-head">
        <div>
          <span class="eyebrow">New account</span>
          <h3>Add user</h3>
        </div>
        <span class="section-note">Password is required before access is created.</span>
      </div>

      <div class="create-grid">
        <label class="field">
          <span>Username</span>
          <input v-model="newUser.username" class="form-control" placeholder="e.g. maria" />
        </label>

        <label class="field">
          <span>Password</span>
          <div class="input-group">
            <input v-model="newUser.password" :type="newUser._showPassword ? 'text' : 'password'" class="form-control" placeholder="Password" />
            <button class="btn btn-outline-secondary" type="button" @click="newUser._showPassword = !newUser._showPassword">
              {{ newUser._showPassword ? 'Hide' : 'Show' }}
            </button>
          </div>
        </label>

        <label class="field">
          <span>Confirm</span>
          <div class="input-group">
            <input v-model="newUser._confirmPassword" :type="newUser._showConfirmPassword ? 'text' : 'password'" class="form-control" placeholder="Repeat password" />
            <button class="btn btn-outline-secondary" type="button" @click="newUser._showConfirmPassword = !newUser._showConfirmPassword">
              {{ newUser._showConfirmPassword ? 'Hide' : 'Show' }}
            </button>
          </div>
        </label>

        <label class="field role-field">
          <span>Role</span>
          <select v-model="newUser.role" class="form-select">
            <option value="USER">User</option>
          </select>
        </label>

        <button class="btn btn-success create-btn" @click="createUser">Create user</button>
      </div>
    </section>

    <section class="users-table-panel">
      <div class="section-head table-head">
        <div>
          <span class="eyebrow">Accounts</span>
          <h3>Access list</h3>
        </div>
        <span class="section-note">Save changes before leaving the row.</span>
      </div>

      <div class="table-responsive">
        <table class="table users-table align-middle mb-0">
          <thead>
            <tr>
              <th style="width: 68px">ID</th>
              <th>Account</th>
              <th style="width: 220px">Role</th>
              <th style="width: 190px">Status</th>
              <th style="width: 240px">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="5" class="text-center">
                <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>
              </td>
            </tr>

            <tr v-else-if="pagedUsers.length === 0">
              <td colspan="5" class="empty-row">
                <strong>No users found.</strong>
                <span>Try a different search or role filter.</span>
              </td>
            </tr>

            <tr v-for="u in pagedUsers" :key="u.id">
              <td class="id-cell">#{{ u.id }}</td>
              <td>
                <div class="account-cell">
                  <img v-if="u.avatarUrl" :src="u.avatarUrl" class="row-avatar" @click="triggerAvatar(u)" />
                  <button v-else class="row-avatar placeholder" type="button" @click="triggerAvatar(u)">
                    {{ userInitial(u) }}
                  </button>
                  <input v-model="u.username" class="form-control username-input" />
                </div>
              </td>
              <td>
                <div class="role-cell">
                  <span class="badge" :class="roleBadgeClass(u.role)">{{ formatRole(u.role) }}</span>
                  <select v-model="u.role" class="form-select">
                    <option value="USER">User</option>
                  </select>
                </div>
              </td>
              <td>
                <div class="status-cell">
                  <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" v-model="u.enabled">
                    <label class="form-check-label visually-hidden">{{ u.enabled ? 'Active' : 'Disabled' }}</label>
                  </div>
                  <span class="badge" :class="u.enabled ? 'bg-success' : 'bg-secondary'">{{ u.enabled ? 'Active' : 'Disabled' }}</span>
                </div>
              </td>
              <td>
                <div class="actions-row">
                  <button class="btn-icon btn-icon-success" title="Save changes" aria-label="Save changes" @click="updateUser(u)">
                    <Icon name="check" :size="18" />
                  </button>

                  <button class="btn-icon btn-icon-warning" title="Change password" aria-label="Change password" @click="u._showPasswordModal = true">
                    <Icon name="key" :size="18" />
                  </button>

                  <div class="avatar-upload-wrapper" title="Change avatar">
                    <button class="btn-icon btn-icon-primary" type="button" aria-label="Change avatar" @click="triggerAvatar(u)">
                      <Icon name="upload" :size="18" />
                    </button>
                    <button v-if="u.avatarUrl" class="btn-remove-avatar" title="Remove avatar" aria-label="Remove avatar" @click.stop="removeAvatar(u)">x</button>
                    <input :ref="'avatarInput' + u.id" type="file" accept="image/*" class="d-none" @change="onAvatarSelected(u, $event)" />
                  </div>

                  <button class="btn-icon btn-icon-danger" title="Delete user" aria-label="Delete user" @click="deleteUser(u)">
                    <Icon name="trash" :size="18" />
                  </button>
                </div>

                <div v-if="u._showPasswordModal" class="password-modal-overlay">
                  <div class="password-modal">
                    <div class="modal-title-block">
                      <span class="eyebrow">Password</span>
                      <h5>Change password</h5>
                      <p>{{ u.username }}</p>
                    </div>

                    <div class="mb-3">
                      <div class="input-group input-group-sm mb-2">
                        <input v-model="u._newPassword" :type="u._showNewPassword ? 'text' : 'password'" class="form-control" placeholder="New password" />
                        <button class="btn btn-outline-secondary" type="button" @click="u._showNewPassword = !u._showNewPassword">
                          <Icon :name="u._showNewPassword ? 'eye-off' : 'eye'" :size="14" />
                        </button>
                      </div>
                      <div class="input-group input-group-sm">
                        <input v-model="u._confirmPassword" :type="u._showConfirmPassword ? 'text' : 'password'" class="form-control" placeholder="Confirm password" />
                        <button class="btn btn-outline-secondary" type="button" @click="u._showConfirmPassword = !u._showConfirmPassword">
                          <Icon :name="u._showConfirmPassword ? 'eye-off' : 'eye'" :size="14" />
                        </button>
                      </div>
                    </div>

                    <div class="d-flex justify-content-end gap-2">
                      <button class="btn btn-secondary btn-sm" @click="u._showPasswordModal = false">Cancel</button>
                      <button class="btn btn-primary btn-sm" @click="changePassword(u); u._showPasswordModal = false">Save</button>
                    </div>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <nav v-if="!loading && totalPages > 1" aria-label="Users pagination" class="users-pagination">
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
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Icon from '../../components/Icon.vue'
import {
  adminGetUsers,
  adminCreateUser,
  adminUpdateUser,
  adminDeleteUser,
  adminChangePassword
} from '../../services/admin.service.js'

export default {
  name: 'AdminUsers',
  components: { Icon },
  data() {
    return {
      loading: false,
      users: [],
      search: '',
      roleFilter: '',
      page: 1,
      pageSize: 10,
      newUser: { username: '', password: '', role: 'USER' },
      toast: null
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    filteredUsers() {
      const s = this.search.trim().toLowerCase()
      return (this.users || []).filter(u => {
        const termMatch = !s || (u.username || '').toLowerCase().includes(s)
        const roleMatch = !this.roleFilter || u.role === this.roleFilter
        return termMatch && roleMatch
      })
    },
    totalPages() {
      return Math.max(1, Math.ceil(this.filteredUsers.length / this.pageSize))
    },
    pagedUsers() {
      const start = (this.page - 1) * this.pageSize
      return this.filteredUsers.slice(start, start + this.pageSize)
    },
    toastClass() {
      if (!this.toast) return ''
      return this.toast.type === 'error' ? 'alert-danger' : 'alert-success'
    }
  },
  watch: {
    pageSize() {
      this.page = 1
      try { localStorage.setItem('adminUsers.pageSize', String(this.pageSize)) } catch (e) { void e }
    },
    roleFilter() {
      this.page = 1
      try { localStorage.setItem('adminUsers.role', this.roleFilter) } catch (e) { void e }
    },
    search() {
      this.page = 1
      try { localStorage.setItem('adminUsers.search', this.search) } catch (e) { void e }
    }
  },
  async mounted() {
    try {
      const s = localStorage.getItem('adminUsers.search')
      if (s !== null) this.search = s
      const rf = localStorage.getItem('adminUsers.role')
      if (rf !== null) this.roleFilter = rf
      const ps = localStorage.getItem('adminUsers.pageSize')
      if (ps !== null) {
        const n = parseInt(ps, 10)
        if (!isNaN(n)) this.pageSize = n
      }
    } catch (e) { void e }
    await this.loadUsers()
  },
  methods: {
    async loadUsers() {
      try {
        this.loading = true
        const res = await adminGetUsers(this.currentUser.id)
        const list = Array.isArray(res.data) ? res.data : []
        this.users = list.map(u => ({ ...u, role: u.role === 'ADMIN' ? 'USER' : u.role }))
      } catch (error) {
        this.showToast('Could not load users', 'error')
      } finally {
        this.loading = false
      }
    },
    userInitial(u) {
      const name = (u && u.username) || ''
      return name ? name.charAt(0).toUpperCase() : '?'
    },
    triggerAvatar(u) {
      const el = this.$refs['avatarInput' + u.id]
      if (el && el[0]) el[0].click()
      else if (el) el.click()
    },
    async onAvatarSelected(u, evt) {
      try {
        const file = evt.target.files && evt.target.files[0]
        evt.target.value = ''
        if (!file) return
        const max = 20 * 1024 * 1024
        const isImage = /^image\//.test(file.type)
        if (!isImage) { this.showToast('Select a valid image', 'error'); return }
        if (file.size > max) { this.showToast('Image must be under 20MB', 'error'); return }
        u._avatarLoading = true
        const { uploadAttachment } = await import('../../services/chat.service.js')
        const res = await uploadAttachment(file)
        const url = res?.data?.url
        if (!url) { this.showToast('Could not upload image', 'error'); return }
        const payload = { username: (u.username || '').trim(), avatarUrl: url, role: u.role, enabled: u.enabled }
        const updated = await adminUpdateUser(this.currentUser.id, u.id, payload)
        Object.assign(u, updated.data)

        if (u.id === this.currentUser.id) {
          this.$store.commit('auth/SET_USER', { ...this.currentUser, avatarUrl: url })
        }

        this.showToast('Avatar updated')
      } catch (error) {
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Could not upload avatar'
        this.showToast(msg, 'error')
      } finally {
        u._avatarLoading = false
      }
    },
    async removeAvatar(u) {
      try {
        if (!confirm('Remove this avatar?')) return
        const payload = { username: u.username, avatarUrl: '', role: u.role, enabled: u.enabled }
        const res = await adminUpdateUser(this.currentUser.id, u.id, payload)
        Object.assign(u, res.data)

        if (u.id === this.currentUser.id) {
          this.$store.commit('auth/SET_USER', { ...this.currentUser, avatarUrl: null })
        }

        this.showToast('Avatar removed')
      } catch (error) {
        this.showToast('Could not remove avatar', 'error')
      }
    },
    formatRole(r) {
      const map = { USER: 'User', SUPER_ADMIN: 'Super admin' }
      return map[r] || r
    },
    roleBadgeClass(r) {
      return r === 'SUPER_ADMIN' ? 'bg-warning text-dark' : 'bg-info'
    },
    async createUser() {
      try {
        const username = (this.newUser.username || '').trim()
        const password = (this.newUser.password || '').trim()
        const confirm = (this.newUser._confirmPassword || '').trim()
        if (!username) { this.showToast('Enter a username', 'error'); return }
        if (!password) { this.showToast('Enter a password', 'error'); return }
        if (password !== confirm) { this.showToast('Passwords do not match', 'error'); return }
        const payload = { username, password, role: this.newUser.role }
        const res = await adminCreateUser(this.currentUser.id, payload)
        this.users.unshift(res.data)
        this.newUser = { username: '', password: '', role: 'USER', _confirmPassword: '', _showPassword: false, _showConfirmPassword: false }
        this.showToast('User created')
      } catch (error) {
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Could not create user'
        this.showToast(msg, 'error')
      }
    },
    async updateUser(u) {
      try {
        const username = (u.username || '').trim()
        if (!username) { this.showToast('Username cannot be empty', 'error'); return }
        const payload = { username, avatarUrl: u.avatarUrl, role: u.role, enabled: u.enabled }
        const res = await adminUpdateUser(this.currentUser.id, u.id, payload)
        Object.assign(u, res.data)

        if (u.id === this.currentUser.id) {
          this.$store.commit('auth/SET_USER', { ...this.currentUser, username: u.username, role: u.role })
        }

        this.showToast('User updated')
      } catch (error) {
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Could not update user'
        this.showToast(msg, 'error')
      }
    },
    async deleteUser(u) {
      try {
        if (!confirm('Delete this user? This cannot be undone.')) return
        await adminDeleteUser(this.currentUser.id, u.id)
        this.users = this.users.filter(x => x.id !== u.id)
        this.showToast('User deleted')
      } catch (error) {
        this.showToast('Could not delete user', 'error')
      }
    },
    async changePassword(u) {
      try {
        const np = (u._newPassword || '').trim()
        const confirm = (u._confirmPassword || '').trim()
        if (!np) { this.showToast('Enter a new password', 'error'); return }
        if (np !== confirm) { this.showToast('Passwords do not match', 'error'); return }
        await adminChangePassword(this.currentUser.id, u.id, np)
        u._newPassword = ''
        u._confirmPassword = ''
        u._showNewPassword = false
        u._showConfirmPassword = false
        this.showToast('Password updated')
      } catch (error) {
        const msg = typeof error?.response?.data === 'string' ? error.response.data : 'Could not change password'
        this.showToast(msg, 'error')
      }
    },
    goTo(p) {
      this.page = Math.min(Math.max(1, p), this.totalPages)
    },
    showToast(message, type = 'success') {
      this.toast = { message, type }
      setTimeout(() => { this.toast = null }, 3000)
    }
  }
}
</script>

<style scoped>
.admin-users {
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

.users-toolbar,
.create-user-panel,
.users-table-panel {
  border: 1px solid rgba(214, 197, 181, 0.72);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.94) 0%, rgba(248, 241, 233, 0.9) 100%);
  box-shadow: 0 16px 30px rgba(76, 56, 38, 0.05);
}

.users-toolbar {
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

.toolbar-controls {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 10px;
}

.search-input {
  width: min(280px, 100%);
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

.create-user-panel,
.users-table-panel {
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

.create-grid {
  display: grid;
  grid-template-columns: minmax(150px, 0.8fr) minmax(220px, 1.2fr) minmax(220px, 1.2fr) 130px auto;
  gap: 12px;
  align-items: end;
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

.create-btn {
  min-width: 128px;
}

.users-table {
  min-width: 940px;
}

.users-table thead th {
  white-space: nowrap;
}

.id-cell {
  color: #8a735f;
  font-weight: 800;
}

.account-cell,
.role-cell,
.status-cell,
.actions-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.row-avatar {
  width: 42px;
  height: 42px;
  flex: 0 0 42px;
  border-radius: 14px;
  border: 1px solid rgba(15, 118, 110, 0.18);
  object-fit: cover;
  color: #0f766e;
  background: linear-gradient(135deg, #d9f2ea, #bfe9d9);
  font-weight: 800;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.row-avatar.placeholder {
  padding: 0;
}

.username-input {
  min-width: 210px;
}

.role-cell .badge,
.status-cell .badge {
  min-width: 82px;
  text-align: center;
}

.actions-row {
  gap: 9px;
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

.btn-icon {
  width: 38px;
  height: 38px;
  border: none;
  border-radius: 13px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #fff;
  transition: transform 0.22s cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 0.22s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.btn-icon:hover {
  transform: translateY(-1px);
}

.btn-icon-success {
  background: linear-gradient(135deg, #0f766e, #15803d);
  box-shadow: 0 10px 18px rgba(15, 118, 110, 0.18);
}

.btn-icon-warning {
  background: linear-gradient(135deg, #d97706, #b45309);
  box-shadow: 0 10px 18px rgba(217, 119, 6, 0.16);
}

.btn-icon-primary {
  background: linear-gradient(135deg, #3f7f72, #0f766e);
  box-shadow: 0 10px 18px rgba(15, 118, 110, 0.14);
}

.btn-icon-danger {
  background: linear-gradient(135deg, #dc2626, #991b1b);
  box-shadow: 0 10px 18px rgba(220, 38, 38, 0.16);
}

.avatar-upload-wrapper {
  position: relative;
  width: 38px;
  height: 38px;
}

.btn-remove-avatar {
  position: absolute;
  top: -6px;
  right: -6px;
  width: 18px;
  height: 18px;
  border: 2px solid #fffaf5;
  border-radius: 999px;
  background: #dc2626;
  color: #fff;
  font-size: 11px;
  line-height: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.password-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(42, 30, 20, 0.38);
  backdrop-filter: blur(5px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
}

.password-modal {
  width: min(380px, calc(100vw - 32px));
  padding: 22px;
  border-radius: 24px;
  border: 1px solid rgba(214, 197, 181, 0.74);
  background: linear-gradient(180deg, #fffdf8 0%, #f7efe5 100%);
  box-shadow: 0 24px 48px rgba(62, 42, 27, 0.16);
}

.modal-title-block {
  margin-bottom: 16px;
}

.modal-title-block h5 {
  margin: 3px 0;
  color: #211913;
  font-weight: 800;
}

.modal-title-block p {
  margin: 0;
  color: #7b6655;
  font-size: 14px;
  font-weight: 700;
}

.users-pagination {
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 1200px) {
  .create-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .create-btn {
    justify-self: start;
  }
}

@media (max-width: 760px) {
  .users-toolbar,
  .section-head {
    align-items: flex-start;
    flex-direction: column;
  }

  .toolbar-controls,
  .search-input,
  .compact-select,
  .page-size,
  .section-note {
    width: 100%;
    text-align: left;
  }

  .create-grid {
    grid-template-columns: 1fr;
  }
}
</style>
