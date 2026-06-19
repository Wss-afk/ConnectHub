<template>
  <div class="group-list">
    <div v-if="loading" class="skeleton">
      <div v-for="n in 5" :key="'skg-'+n" class="sk-row">
        <div class="sk-avatar"></div>
        <div class="sk-lines">
          <div class="sk-line sk-line-1"></div>
          <div class="sk-line sk-line-2"></div>
        </div>
      </div>
    </div>
    <div v-else-if="groups.length === 0" class="empty">
      <div class="empty-hero" aria-hidden="true">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="4" y="6" width="16" height="12" rx="3" stroke="currentColor" stroke-width="2" opacity=".25" />
          <path d="M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        </svg>
      </div>
      <div class="empty-title">No hay grupos</div>
      <div class="empty-sub">Contacta con tu admin para crear un grupo</div>
      <button class="empty-cta" type="button" @click="$emit('refresh')">Actualizar</button>
    </div>
    <transition-group v-else name="list-fade" tag="ul" class="list">
      <li
        v-for="group in groups"
        :key="group.id"
        @click="$emit('select', group)"
        class="row"
        :class="{ active: selectedGroup && selectedGroup.id === group.id }"
      >
        <div class="avatar-wrap">
          <div class="avatar group-avatar" :title="group.name" role="img" :aria-label="'Grupo ' + group.name">{{ initials(group.name) }}</div>
        </div>
        <div class="info">
          <div class="top">
            <div class="name">{{ group.name }}</div>
          </div>
          <div class="bottom">
            <div class="sub">{{ group.users ? group.users.length : 0 }} miembros</div>
            <span v-if="groupUnreadCounts[group.id] > 0" class="unread">{{ groupUnreadCounts[group.id] }}</span>
          </div>
        </div>
      </li>
    </transition-group>
  </div>
</template>

<script>
export default {
  name: 'GroupList',
  props: {
    groups: {
      type: Array,
      required: true
    },
    loading: { type: Boolean, default: false },
    groupUnreadCounts: {
      type: Object,
      default: () => ({})
    },
    selectedGroup: {
      type: Object,
      default: null
    }
  },
  methods: {
    initials(name) {
      const parts = (name || '').trim().split(/\s+/).filter(Boolean)
      return (parts[0] || 'G')[0].toUpperCase()
    }
  }
}
</script>

<style scoped>
.group-list { padding: 0; }
.list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; }

.row {
  padding: 12px 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 10px;
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--border-color);
  position: relative;
  transition: all .2s ease;
}
.row:first-child { border-top: 1px solid var(--border-color); }
.row:hover { background: linear-gradient(90deg, rgba(79,70,229,0.04) 0%, transparent 100%); transform: translateX(2px); }
.row.active { background: linear-gradient(90deg, rgba(79,70,229,0.07) 0%, rgba(79,70,229,0.02) 100%); }

.row::before {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 0;
  background: linear-gradient(180deg, var(--brand-gradient-start), var(--brand-gradient-end));
  transition: width .2s ease;
  border-radius: 0 4px 4px 0;
}
.row:hover::before, .row.active::before { width: 3px; }

.avatar-wrap { width: 34px; height: 34px; }
.avatar.group-avatar {
  width: 34px; height: 34px; border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 13px;
  background: linear-gradient(135deg, var(--brand-gradient-start), var(--brand-gradient-end));
  color: #fff;
  box-shadow: 0 2px 8px rgba(79,70,229,0.25);
  transition: transform 0.2s ease;
}
.row:hover .avatar.group-avatar { transform: scale(1.08); }

.info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.top { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.bottom { display: flex; align-items: center; justify-content: space-between; gap: 8px; }

.name { font-weight: 600; color: #334155; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; transition: color .2s ease; }
.sub { font-size: 13px; color: #64748b; transition: color .2s ease; flex: 1; }
.row:hover .name { color: var(--brand-gradient-start); }
.row:hover .sub { color: #4b5563; }

.unread {
  background: linear-gradient(135deg, #f87171, #ef4444);
  color: #fff; border-radius: 9999px;
  min-width: 20px; height: 20px; padding: 0 6px;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 700;
  animation: badgePulse 1.4s ease-in-out infinite;
  box-shadow: 0 2px 8px rgba(239, 68, 68, 0.35);
}

@media (max-width: 768px) {
  .row { padding: 10px 14px; }
  .name { font-size: 13px; }
  .unread { min-width: 18px; height: 18px; font-size: 10px; }
}

@media (max-width: 480px) {
  .row { padding: 8px 12px; }
  .name { font-size: 12px; }
}

/* Animaciones */
.list-fade-enter-active, .list-fade-leave-active { transition: all .25s ease; }
.list-fade-enter-from, .list-fade-leave-to { opacity: 0; transform: translateY(6px); }

@keyframes badgePulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.08); }
}

/* Skeleton */
.skeleton { display: flex; flex-direction: column; gap: 12px; padding: 8px; }
.sk-row { display: flex; align-items: center; gap: 12px; }
.sk-avatar {
  width: 34px; height: 34px; border-radius: 50%;
  background: linear-gradient(90deg, #e5e7eb, #d1d5db, #e5e7eb);
  background-size: 200% 100%;
  animation: shimmer 1.2s infinite;
}
.sk-lines { flex: 1; display: flex; flex-direction: column; gap: 6px; }
.sk-line { height: 10px; background: linear-gradient(90deg, #f1f5f9, #e2e8f0, #f1f5f9); border-radius: 8px; animation: shimmer 1.2s infinite; }
.sk-line-1 { width: 40%; }
.sk-line-2 { width: 60%; opacity: .9; }
@keyframes shimmer { 0% { background-position: -200px 0; } 100% { background-position: 200px 0; } }

/* Empty state */
.empty { text-align: center; padding: 20px; color: #64748b; }
.empty-hero {
  display: inline-flex; align-items: center; justify-content: center;
  color: #94a3b8; margin-bottom: 10px;
  background: #f1f5f9; width: 56px; height: 56px; border-radius: 50%;
}
.empty-title { font-weight: 800; color: #334155; font-size: 14px; }
.empty-sub { font-size: 12px; margin-top: 4px; color: #94a3b8; }
.empty-cta {
  margin-top: 12px; padding: 8px 16px; border-radius: 10px;
  border: 1px solid rgba(79,70,229,0.15);
  background: linear-gradient(135deg, #eef2ff, #e0e7ff);
  color: #4f46e5; font-weight: 700; cursor: pointer;
  transition: all 0.2s ease;
}
.empty-cta:hover { background: linear-gradient(135deg, #e0e7ff, #c7d2fe); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(79,70,229,0.15); }
</style>
