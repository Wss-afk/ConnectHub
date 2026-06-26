<template>
  <div class="admin-groups">
    <section class="groups-toolbar">
      <div class="toolbar-copy">
        <span class="eyebrow">Teams</span>
        <strong>{{ filteredGroups.length }} groups in view</strong>
      </div>
      <div class="toolbar-controls">
        <input v-model="searchGroup" class="form-control search-input" placeholder="Search groups" />
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

    <section class="create-group-panel">
      <div class="section-head">
        <div>
          <span class="eyebrow">New group</span>
          <h3>Create team space</h3>
        </div>
        <span class="section-note">{{ newGroup.memberIds.length }} members selected.</span>
      </div>

      <div class="create-layout">
        <label class="field group-name-field">
          <span>Group name</span>
          <input v-model="newGroup.name" class="form-control" placeholder="e.g. Support desk" />
        </label>
        <button class="btn btn-success create-btn" @click="createGroup" :disabled="!hasName">Create group</button>
      </div>

      <div class="member-picker" :class="{ 'members-disabled': !hasName }">
        <div class="member-picker-head">
          <span>Assign members</span>
          <small>Name the group first, then pick people.</small>
        </div>
        <div class="members-list">
          <label v-for="u in users" :key="'c-' + u.id" class="member-item" :class="{ checked: newGroup.memberIds.includes(u.id) }">
            <input type="checkbox" :value="u.id" v-model="newGroup.memberIds" :disabled="!hasName" />
            <span class="member-avatar">{{ userInitial(u) }}</span>
            <span class="member-name">{{ u.username }}</span>
          </label>
        </div>
      </div>
    </section>

    <section class="groups-table-panel">
      <div class="section-head table-head">
        <div>
          <span class="eyebrow">Membership</span>
          <h3>Group list</h3>
        </div>
        <span class="section-note">Group edits change message visibility.</span>
      </div>

      <div class="table-responsive">
        <table class="table groups-table align-middle mb-0">
          <thead>
            <tr>
              <th style="width: 68px">ID</th>
              <th>Group</th>
              <th style="width: 180px">Members</th>
              <th style="width: 190px">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="4" class="text-center">
                <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>
              </td>
            </tr>

            <tr v-else-if="pagedGroups.length === 0">
              <td colspan="4" class="empty-row">
                <strong>No groups found.</strong>
                <span>Create one or change the search.</span>
              </td>
            </tr>

            <tr
              v-for="g in pagedGroups"
              :key="g.id"
              :class="{ selected: selectedGroup && selectedGroup.id === g.id }"
              @click="selectGroup(g)"
            >
              <td class="id-cell">#{{ g.id }}</td>
              <td>
                <div class="group-cell">
                  <span class="group-mark">{{ groupInitial(g) }}</span>
                  <div>
                    <strong>{{ g.name }}</strong>
                    <small>{{ memberPreview(g) }}</small>
                  </div>
                </div>
              </td>
              <td>
                <span class="badge" :class="memberBadgeClass(g)">{{ memberBadgeText(g) }}</span>
              </td>
              <td>
                <div class="actions-row">
                  <button class="btn btn-secondary btn-sm" @click.stop="editGroup(g)">Edit</button>
                  <button class="btn btn-danger btn-sm" @click.stop="deleteGroup(g)">Delete</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <nav v-if="!loading && totalPages > 1" aria-label="Groups pagination" class="groups-pagination">
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

    <div v-if="editModalOpen" class="modal-backdrop-custom">
      <div class="modal-custom" role="dialog" aria-modal="true" aria-labelledby="editGroupModalTitle">
        <div class="modal-header">
          <div>
            <span class="eyebrow">Group</span>
            <h5 id="editGroupModalTitle">Edit group</h5>
          </div>
          <button type="button" class="btn-close" @click="closeEdit"></button>
        </div>

        <div class="modal-body">
          <div class="edit-name-row">
            <label class="field">
              <span>Name</span>
              <input v-model="editName" class="form-control" placeholder="Group name" />
            </label>
            <button class="btn btn-primary" @click="saveEditName" :disabled="!editNameChanged">Save name</button>
            <button class="btn btn-outline-danger" @click="confirmDelete">Delete group</button>
          </div>

          <div class="edit-members-head">
            <input v-model="memberSearch" class="form-control search-input" placeholder="Search members" />
            <button class="btn btn-success" @click="saveEditMembers" :disabled="!editMembersChanged">Save members</button>
          </div>

          <div class="members-list edit-members-list">
            <label v-for="u in filteredMembers" :key="'e-' + u.id" class="member-item" :class="{ checked: editMemberIds.includes(u.id) }">
              <input type="checkbox" :value="u.id" v-model="editMemberIds" />
              <span class="member-avatar">{{ userInitial(u) }}</span>
              <span class="member-name">{{ u.username }}</span>
            </label>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeEdit">Close</button>
          <button class="btn btn-primary" @click="saveAllEdits" :disabled="!editNameChanged && !editMembersChanged">Save all</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import {
  adminGetGroups,
  adminCreateGroup,
  adminUpdateGroup,
  adminDeleteGroup,
  adminUpdateGroupMembers,
  adminGetUsers
} from '../../services/admin.service.js'

export default {
  name: 'AdminGroups',
  data() {
    return {
      loading: false,
      groups: [],
      users: [],
      searchGroup: '',
      page: 1,
      pageSize: 10,
      newGroup: { name: '', memberIds: [] },
      selectedGroup: null,
      selectedMemberIds: [],
      memberSearch: '',
      toast: null,
      editModalOpen: false,
      editTargetGroup: null,
      editName: '',
      editMemberIds: []
    }
  },
  computed: {
    ...mapGetters('auth', ['currentUser']),
    hasName() {
      return (this.newGroup.name || '').trim().length > 0
    },
    filteredGroups() {
      const s = this.searchGroup.trim().toLowerCase()
      return (this.groups || []).filter(g => !s || (g.name || '').toLowerCase().includes(s))
    },
    totalPages() {
      return Math.max(1, Math.ceil(this.filteredGroups.length / this.pageSize))
    },
    pagedGroups() {
      const start = (this.page - 1) * this.pageSize
      return this.filteredGroups.slice(start, start + this.pageSize)
    },
    filteredMembers() {
      const s = this.memberSearch.trim().toLowerCase()
      return (this.users || []).filter(u => !s || (u.username || '').toLowerCase().includes(s))
    },
    hasMemberChanges() {
      const originalIds = (this.selectedGroup?.users || []).map(u => u.id).sort().join(',')
      const selectedIds = [...this.selectedMemberIds].sort().join(',')
      return originalIds !== selectedIds
    },
    editNameChanged() {
      if (!this.editTargetGroup) return false
      return (this.editName || '').trim() !== (this.editTargetGroup.name || '')
    },
    editMembersChanged() {
      if (!this.editTargetGroup) return false
      const originalIds = (this.editTargetGroup?.users || []).map(u => u.id).sort().join(',')
      const selectedIds = [...this.editMemberIds].sort().join(',')
      return originalIds !== selectedIds
    },
    toastClass() {
      if (!this.toast) return ''
      return this.toast.type === 'error' ? 'alert-danger' : 'alert-success'
    }
  },
  watch: {
    pageSize() {
      this.page = 1
      try { localStorage.setItem('adminGroups.pageSize', String(this.pageSize)) } catch (e) { void e }
    },
    searchGroup() {
      this.page = 1
      try { localStorage.setItem('adminGroups.search', this.searchGroup) } catch (e) { void e }
    }
  },
  async mounted() {
    try {
      const s = localStorage.getItem('adminGroups.search')
      if (s !== null) this.searchGroup = s
      const ps = localStorage.getItem('adminGroups.pageSize')
      if (ps !== null) {
        const n = parseInt(ps, 10)
        if (!isNaN(n)) this.pageSize = n
      }
    } catch (e) { void e }
    await Promise.all([this.loadGroups(), this.loadUsers()])
  },
  methods: {
    memberBadgeText(g) {
      const n = (g.users || []).length
      return n === 0 ? 'No members' : `${n} member${n === 1 ? '' : 's'}`
    },
    memberBadgeClass(g) {
      const n = (g.users || []).length
      if (n === 0) return 'bg-secondary'
      if (n < 5) return 'bg-info'
      return 'bg-success'
    },
    memberPreview(g) {
      const names = (g.users || []).slice(0, 3).map(u => u.username).filter(Boolean)
      if (!names.length) return 'No members assigned'
      const extra = (g.users || []).length - names.length
      return extra > 0 ? `${names.join(', ')} +${extra}` : names.join(', ')
    },
    userInitial(u) {
      const name = (u && u.username) || ''
      return name ? name.charAt(0).toUpperCase() : '?'
    },
    groupInitial(g) {
      const name = (g && g.name) || ''
      return name ? name.charAt(0).toUpperCase() : '#'
    },
    editGroup(g) {
      this.editTargetGroup = g
      this.editName = g.name
      this.editMemberIds = (g.users || []).map(u => u.id)
      this.editModalOpen = true
    },
    closeEdit() {
      this.editModalOpen = false
      this.editTargetGroup = null
      this.editName = ''
      this.editMemberIds = []
    },
    async loadGroups() {
      try {
        this.loading = true
        const res = await adminGetGroups(this.currentUser.id)
        this.groups = res.data
      } catch (error) {
        this.showToast('Could not load groups', 'error')
      } finally {
        this.loading = false
      }
    },
    async saveEditName() {
      if (!this.editTargetGroup) return
      try {
        const res = await adminUpdateGroup(this.currentUser.id, this.editTargetGroup.id, { name: (this.editName || '').trim() })
        Object.assign(this.editTargetGroup, res.data)
        this.showToast('Group name updated')
      } catch (error) {
        this.showToast('Could not update group name', 'error')
      }
    },
    async saveEditMembers() {
      if (!this.editTargetGroup) return
      try {
        await adminUpdateGroupMembers(this.currentUser.id, this.editTargetGroup.id, this.editMemberIds)
        await this.loadGroups()
        const again = this.groups.find(x => x.id === this.editTargetGroup.id)
        this.editTargetGroup = again || this.editTargetGroup
        this.showToast('Members updated')
      } catch (error) {
        this.showToast('Could not update members', 'error')
      }
    },
    async saveAllEdits() {
      await Promise.all([
        this.editNameChanged ? this.saveEditName() : Promise.resolve(),
        this.editMembersChanged ? this.saveEditMembers() : Promise.resolve()
      ])
      this.closeEdit()
    },
    async confirmDelete() {
      if (!this.editTargetGroup) return
      if (!confirm('Delete this group? This changes member access.')) return
      await this.deleteGroup(this.editTargetGroup, true)
      this.closeEdit()
    },
    async loadUsers() {
      try {
        const res = await adminGetUsers(this.currentUser.id)
        this.users = res.data
      } catch (error) {
        this.showToast('Could not load users', 'error')
      }
    },
    selectGroup(g) {
      this.selectedGroup = g
      const memberIds = (g.users || []).map(u => u.id)
      this.selectedMemberIds = memberIds
    },
    async createGroup() {
      try {
        const name = (this.newGroup.name || '').trim()
        if (!name) { this.showToast('Enter a group name', 'error'); return }
        const payload = { name, userIds: this.newGroup.memberIds }
        const res = await adminCreateGroup(this.currentUser.id, payload)
        this.groups.unshift(res.data)
        this.newGroup = { name: '', memberIds: [] }
        this.showToast('Group created')
      } catch (error) {
        this.showToast('Could not create group', 'error')
      }
    },
    async updateGroup(g) {
      try {
        const res = await adminUpdateGroup(this.currentUser.id, g.id, { name: g.name })
        Object.assign(g, res.data)
        this.showToast('Group updated')
      } catch (error) {
        this.showToast('Could not update group', 'error')
      }
    },
    async deleteGroup(g, alreadyConfirmed = false) {
      try {
        if (!alreadyConfirmed && !confirm('Delete this group? This changes member access.')) return
        await adminDeleteGroup(this.currentUser.id, g.id)
        this.groups = this.groups.filter(x => x.id !== g.id)
        if (this.selectedGroup && this.selectedGroup.id === g.id) {
          this.selectedGroup = null
          this.selectedMemberIds = []
        }
        this.showToast('Group deleted')
      } catch (error) {
        this.showToast('Could not delete group', 'error')
      }
    },
    async saveGroupMembers() {
      if (!this.selectedGroup) return
      try {
        await adminUpdateGroupMembers(this.currentUser.id, this.selectedGroup.id, this.selectedMemberIds)
        this.showToast('Members updated')
        await this.loadGroups()
        const again = this.groups.find(g => g.id === this.selectedGroup.id)
        this.selectGroup(again)
      } catch (error) {
        this.showToast('Could not update members', 'error')
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
.admin-groups {
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

.groups-toolbar,
.create-group-panel,
.groups-table-panel {
  border: 1px solid rgba(214, 197, 181, 0.72);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.94) 0%, rgba(248, 241, 233, 0.9) 100%);
  box-shadow: 0 16px 30px rgba(76, 56, 38, 0.05);
}

.groups-toolbar {
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

.create-group-panel,
.groups-table-panel {
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

.create-layout {
  display: grid;
  grid-template-columns: minmax(240px, 1fr) auto;
  gap: 12px;
  align-items: end;
  padding: 18px 18px 12px;
}

.field {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.field > span,
.member-picker-head > span {
  color: #6f5a48;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.create-btn {
  min-width: 132px;
}

.member-picker {
  padding: 0 18px 18px;
}

.member-picker-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 10px;
}

.member-picker-head small {
  color: #7b6655;
  font-weight: 700;
}

.members-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 8px;
  max-height: 240px;
  overflow: auto;
  padding-right: 4px;
}

.member-item {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 9px 10px;
  border-radius: 14px;
  border: 1px solid rgba(214, 197, 181, 0.6);
  background: rgba(255, 251, 246, 0.72);
  color: #2b2119;
  cursor: pointer;
  transition: background 0.22s cubic-bezier(0.22, 0.61, 0.36, 1), border-color 0.22s cubic-bezier(0.22, 0.61, 0.36, 1);
}

.member-item:hover,
.member-item.checked {
  border-color: rgba(15, 118, 110, 0.24);
  background: rgba(226, 246, 237, 0.72);
}

.member-avatar,
.group-mark {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #0f766e;
  background: linear-gradient(135deg, #d9f2ea, #bfe9d9);
  font-weight: 800;
}

.member-avatar {
  width: 28px;
  height: 28px;
  border-radius: 10px;
}

.member-name {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 700;
}

.members-disabled {
  opacity: 0.62;
}

.groups-table {
  min-width: 780px;
}

.id-cell {
  color: #8a735f;
  font-weight: 800;
}

.group-cell {
  display: flex;
  align-items: center;
  gap: 11px;
}

.group-mark {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  flex: 0 0 42px;
}

.group-cell strong,
.group-cell small {
  display: block;
}

.group-cell strong {
  color: #211913;
  font-size: 15px;
}

.group-cell small {
  color: #7b6655;
  font-weight: 600;
}

.groups-table tr.selected {
  background: rgba(226, 246, 237, 0.54);
}

.actions-row {
  display: flex;
  align-items: center;
  gap: 8px;
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

.groups-pagination {
  display: flex;
  justify-content: flex-end;
}

.modal-backdrop-custom {
  position: fixed;
  inset: 0;
  background: rgba(42, 30, 20, 0.38);
  backdrop-filter: blur(5px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1050;
}

.modal-custom {
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

.modal-header,
.modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 20px;
  border-color: rgba(214, 197, 181, 0.66);
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

.edit-name-row,
.edit-members-head {
  display: flex;
  align-items: end;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 14px;
}

.edit-name-row .field {
  flex: 1 1 240px;
}

.edit-members-list {
  max-height: 320px;
}

@media (max-width: 760px) {
  .groups-toolbar,
  .section-head,
  .member-picker-head {
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

  .create-layout {
    grid-template-columns: 1fr;
  }

  .create-btn {
    justify-self: start;
  }
}
</style>
