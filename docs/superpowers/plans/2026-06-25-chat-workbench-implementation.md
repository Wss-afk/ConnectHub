# Chat Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the chat page into a clearer, denser, warmer collaboration workbench without changing chat behavior.

**Architecture:** Keep the current data flow and WebSocket behavior intact, but reorganize the chat shell into a stronger two-zone layout: conversation rail on the left and message stage on the right. Most work stays inside the existing Vue single-file components, with only a light cleanup in shared theme tokens where the chat page still depends on conflicting values.

**Tech Stack:** Vue 3, Vue Router, Vuex, scoped CSS, shared design tokens in `src/assets/theme.css`, verification through `npm run lint`, `npm run build`, and browser review.

---

## Notes Before Execution

- This repository does **not** currently include a component test runner such as Vitest or Cypress.
- For this phase, use this verification loop on every task:
  - Edit the component
  - Run `npm run lint`
  - Run `npm run build`
  - Review the page in the browser at `/chat`
- Do **not** change chat logic, message transport, unread logic, routing, or API contracts in this phase.

### File Map

- `chatroom_frontend/src/views/Chat.vue`
  - Owns the page shell, rail/message-stage split, tab framing, empty-chat state, and composer area placement.
- `chatroom_frontend/src/components/ChatWindow.vue`
  - Owns the in-chat header, group members strip, message stream, jump-to-latest controls, and composer frame.
- `chatroom_frontend/src/components/UserList.vue`
  - Owns direct-chat conversation rows, online state dot, preview rhythm, unread placement.
- `chatroom_frontend/src/components/GroupList.vue`
  - Owns group conversation rows and unread state.
- `chatroom_frontend/src/components/MessageItem.vue`
  - Owns message bubble density, attachment blocks, timestamps, continuation treatment.
- `chatroom_frontend/src/assets/theme.css`
  - Owns shared color, spacing, radius, and easing tokens used by the chat redesign.

---

### Task 1: Rebuild the Chat Page Shell

**Files:**
- Modify: `chatroom_frontend/src/views/Chat.vue`
- Verify: `chatroom_frontend/package.json`

- [ ] **Step 1: Rewrite the chat shell template to emphasize the two-zone layout**

Target structure:

```vue
<div class="chat-page">
  <AppDock />
  <section class="chat-shell">
    <header class="chat-page-header">
      <div class="chat-page-title-wrap">
        <h1 class="chat-page-title">Messages</h1>
        <p class="chat-page-subtitle">Unread first. Noise last.</p>
      </div>
    </header>

    <div class="chat-workbench">
      <aside class="conversation-rail">
        <div class="rail-header">
          <nav class="chats-tabs" role="tablist" aria-label="Chat list">
            <button :class="['tab', activeTab === 'all' && 'active']" @click="activeTab='all'">All</button>
            <button :class="['tab', activeTab === 'contacts' && 'active']" @click="activeTab='contacts'">Contacts</button>
            <button :class="['tab', activeTab === 'groups' && 'active']" @click="activeTab='groups'">Groups</button>
          </nav>
        </div>
        <div class="rail-body">
          <template v-if="activeTab==='all'">
            <UserList
              :users="sortedUsers"
              :loading="loadingUsers"
              :unreadCounts="unreadCounts"
              :selectedUser="selectedUser"
              :onlineUsers="onlineUsers"
              :lastMessageMap="lastMessageMap"
              @select="selectUser"
              @refresh="refreshUsers"
            />
            <div class="divider"></div>
            <GroupList
              :groups="groups"
              :loading="loadingGroups"
              :groupUnreadCounts="groupUnreadCounts"
              :selectedGroup="selectedGroup"
              @select="selectGroup"
              @refresh="refreshGroups"
            />
          </template>
          <template v-else-if="activeTab==='contacts'">
            <UserList
              :users="sortedUsers"
              :loading="loadingUsers"
              :unreadCounts="unreadCounts"
              :selectedUser="selectedUser"
              :onlineUsers="onlineUsers"
              :lastMessageMap="lastMessageMap"
              @select="selectUser"
              @refresh="refreshUsers"
            />
          </template>
          <template v-else>
            <GroupList
              :groups="groups"
              :loading="loadingGroups"
              :groupUnreadCounts="groupUnreadCounts"
              :selectedGroup="selectedGroup"
              @select="selectGroup"
              @refresh="refreshGroups"
            />
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
            @compose="focusComposer"
          >
            <div class="chat-input-area">
              <div class="chat-input-actions gap8-2">
                <button class="icon-btn" type="button" @click="toggleEmojiPicker">
                  <Icon name="smile" :size="18" />
                </button>
                <button class="icon-btn" type="button" @click="triggerAttach">
                  <Icon name="paperclip" :size="18" />
                </button>
              </div>
              <input ref="composerInput" v-model="inputMsg" @keyup.enter="send" placeholder="Type a message..." />
              <button @click="send" class="send-btn">
                <Icon name="send" :size="18" />
                <span class="send-label">Send</span>
              </button>
            </div>
          </ChatWindow>
        </template>
        <template v-else>
          <div class="empty-chat" aria-live="polite">
            <div class="empty-chat-panel" role="region" aria-label="Select a chat">
              <div class="empty-chat-mark" aria-hidden="true">
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
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
```

- [ ] **Step 2: Replace the page-level styles in `Chat.vue` with stronger shell hierarchy**

Target CSS block:

```css
.chat-page {
  display: flex;
  min-height: 100vh;
  background:
    radial-gradient(circle at 12% 18%, rgba(15, 118, 110, 0.05), transparent 28%),
    radial-gradient(circle at 88% 82%, rgba(217, 119, 6, 0.05), transparent 24%),
    linear-gradient(145deg, #f8f4ee 0%, #fcfbf8 52%, #f5efe8 100%);
}

.chat-shell {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  padding: 20px 22px;
}

.chat-page-header {
  margin-bottom: 18px;
}

.chat-page-title {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  letter-spacing: -0.04em;
  color: #1c1917;
}

.chat-page-subtitle {
  margin: 6px 0 0;
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

.conversation-rail,
.message-stage {
  min-height: 0;
  border-radius: 28px;
}
```

- [ ] **Step 3: Rebuild the rail and stage framing styles**

Target CSS block:

```css
.conversation-rail {
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, rgba(255,255,255,0.88) 0%, rgba(249,245,239,0.96) 100%);
  border: 1px solid rgba(120, 104, 85, 0.12);
  box-shadow: 0 14px 34px rgba(28, 18, 10, 0.06);
  overflow: hidden;
}

.rail-header {
  padding: 16px 16px 10px;
  border-bottom: 1px solid rgba(120, 104, 85, 0.08);
}

.rail-body {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.message-stage {
  display: flex;
  flex-direction: column;
  min-width: 0;
}
```

- [ ] **Step 4: Simplify the empty-chat state so it stops behaving like a promo card**

Target markup:

```vue
<div class="empty-chat" aria-live="polite">
  <div class="empty-chat-panel" role="region" aria-label="Select a chat">
    <div class="empty-chat-mark" aria-hidden="true">
      <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
        <path d="M4 5.5A3.5 3.5 0 0 1 7.5 2h9A3.5 3.5 0 0 1 20 5.5v7A3.5 3.5 0 0 1 16.5 16H13l-3.5 3.5c-.6.6-1.5.18-1.5-.7V16H7.5A3.5 3.5 0 0 1 4 12.5v-7Z" fill="currentColor"/>
      </svg>
    </div>
    <div class="empty-chat-title">Pick a chat</div>
    <div class="empty-chat-text">Unread is waiting on the left.</div>
  </div>
</div>
```

Target CSS:

```css
.empty-chat {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
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
```

- [ ] **Step 5: Add responsive rules for the new shell without changing routing behavior**

Target CSS:

```css
@media (max-width: 1024px) {
  .chat-workbench {
    grid-template-columns: 280px minmax(0, 1fr);
  }
}

@media (max-width: 768px) {
  .chat-shell {
    padding: 14px;
  }

  .chat-workbench {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .conversation-rail {
    max-height: 240px;
  }
}
```

- [ ] **Step 6: Run lint to verify the shell rewrite is valid**

Run:

```powershell
cd chatroom_frontend
npm run lint
```

Expected: lint passes with no new errors in `src/views/Chat.vue`.

- [ ] **Step 7: Run build to verify the page still compiles**

Run:

```powershell
cd chatroom_frontend
npm run build
```

Expected: production build completes successfully.

---

### Task 2: Unify the Conversation Rail

**Files:**
- Modify: `chatroom_frontend/src/components/UserList.vue`
- Modify: `chatroom_frontend/src/components/GroupList.vue`

- [ ] **Step 1: Tighten direct-chat row markup in `UserList.vue`**

Target structure:

```vue
<li
  class="conversation-row"
  :class="{
    active: selectedUser && selectedUser.id === user.id,
    online: isUserOnline(user),
    unread: unreadCounts[user.id] > 0
  }"
>
  <div class="conversation-avatar-wrap">
    <img v-if="user.avatarUrl" :src="user.avatarUrl" class="avatar" :alt="'Avatar of ' + user.username" />
    <div v-else class="avatar placeholder">{{ initials(user.username) }}</div>
    <span class="status-dot" :class="isUserOnline(user) ? 'online' : 'offline'" />
  </div>
  <div class="conversation-copy">
    <div class="conversation-topline">
      <div class="conversation-name">{{ user.username }}</div>
      <div class="conversation-time">{{ formattedTime(lastMessageMap[user.id]?.timestamp) }}</div>
    </div>
    <div class="conversation-bottomline">
      <div class="conversation-preview">{{ formatPreview(user.id) }}</div>
      <span v-if="unreadCounts[user.id] > 0" class="conversation-unread">{{ unreadCounts[user.id] }}</span>
    </div>
  </div>
</li>
```

- [ ] **Step 2: Replace direct-chat row styles with a calmer, denser system**

Target CSS:

```css
.conversation-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  margin: 0 10px 6px;
  border-radius: 18px;
  border: 1px solid transparent;
  background: transparent;
  transition: transform 180ms cubic-bezier(0.22, 0.61, 0.36, 1),
              background-color 180ms cubic-bezier(0.22, 0.61, 0.36, 1),
              border-color 180ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.conversation-row:hover {
  transform: translateX(2px);
  background: rgba(15, 118, 110, 0.05);
}

.conversation-row.active {
  background: linear-gradient(135deg, rgba(15,118,110,0.12), rgba(15,118,110,0.05));
  border-color: rgba(15,118,110,0.16);
}
```

- [ ] **Step 3: Apply the same rail rhythm to `GroupList.vue`**

Target structure:

```vue
<li
  class="conversation-row group-row"
  :class="{ active: selectedGroup && selectedGroup.id === group.id }"
>
  <div class="conversation-avatar-wrap">
    <div class="group-avatar">{{ initials(group.name) }}</div>
  </div>
  <div class="conversation-copy">
    <div class="conversation-topline">
      <div class="conversation-name">{{ group.name }}</div>
    </div>
    <div class="conversation-bottomline">
      <div class="conversation-preview">{{ group.users ? group.users.length : 0 }} members</div>
      <span v-if="groupUnreadCounts[group.id] > 0" class="conversation-unread">{{ groupUnreadCounts[group.id] }}</span>
    </div>
  </div>
</li>
```

- [ ] **Step 4: Lighten the user/group split in `Chat.vue`**

Target divider CSS:

```css
.divider {
  height: 1px;
  margin: 6px 16px 8px;
  background: linear-gradient(90deg, transparent, rgba(120, 104, 85, 0.16), transparent);
}
```

- [ ] **Step 5: Verify rail changes**

Run:

```powershell
cd chatroom_frontend
npm run lint
npm run build
```

Expected: both commands pass and the rail still renders users, groups, unread badges, and online dots.

---

### Task 3: Reframe the Message Stage

**Files:**
- Modify: `chatroom_frontend/src/components/ChatWindow.vue`

- [ ] **Step 1: Tighten the chat header structure**

Target template:

```vue
<div class="chat-topbar">
  <div class="chat-context">
    <div class="chat-avatar" v-if="chatType === 'user'">
      <img v-if="chatUser && chatUser.avatarUrl" :src="chatUser.avatarUrl" class="avatar-img" alt="avatar" />
      <span v-else>{{ userInitial }}</span>
    </div>
    <div class="chat-avatar group" v-else>
      {{ groupInitial }}
    </div>
    <div class="chat-meta">
      <div class="chat-name">{{ chatType === 'user' ? chatUser.username : chatGroup.name }}</div>
      <div class="chat-sub">
        {{ chatType === 'user'
          ? (chatUser.email || chatUser.userEmail || 'Private chat')
          : ((chatGroup.users && chatGroup.users.length) ? (chatGroup.users.length + ' members') : 'Group') }}
      </div>
    </div>
  </div>
  <div class="chat-tools">
    <input
      class="chat-search"
      type="text"
      :value="searchQuery"
      :placeholder="chatType === 'user' ? 'Search this chat' : 'Search this group'"
      @input="onInputSearch"
      @keyup.enter="$emit('search', localSearch)"
    />
  </div>
</div>
```

- [ ] **Step 2: Rebuild the message-stage framing styles**

Target CSS:

```css
.chat-window {
  position: relative;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 18px;
  border-radius: 28px;
  background: linear-gradient(180deg, rgba(255,255,255,0.95) 0%, rgba(248,243,236,0.92) 100%);
  border: 1px solid rgba(120, 104, 85, 0.1);
  box-shadow: 0 18px 42px rgba(28, 18, 10, 0.06);
}

.chat-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 12px 14px;
  border-radius: 18px;
  background: rgba(255,255,255,0.75);
  border: 1px solid rgba(120, 104, 85, 0.08);
}
```

- [ ] **Step 3: Lighten the group member strip**

Target CSS:

```css
.group-members-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  margin-top: 10px;
  margin-bottom: 10px;
  border-radius: 14px;
  background: rgba(245, 240, 234, 0.9);
  border: 1px solid rgba(120, 104, 85, 0.08);
}

.member-chip {
  padding: 4px 9px;
  border-radius: 999px;
  background: rgba(15,118,110,0.08);
  color: #115e59;
  box-shadow: none;
}
```

- [ ] **Step 4: Reduce the visual weight of empty and loading states inside the message stream**

Target CSS:

```css
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
```

- [ ] **Step 5: Re-anchor the composer frame**

Target CSS:

```css
.composer-bar {
  position: sticky;
  bottom: 0;
  margin-top: 10px;
  padding: 10px;
  border-radius: 18px;
  background: rgba(255,255,255,0.9);
  border: 1px solid rgba(120, 104, 85, 0.1);
  backdrop-filter: blur(10px);
}
```

- [ ] **Step 6: Verify message-stage framing**

Run:

```powershell
cd chatroom_frontend
npm run lint
npm run build
```

Expected: header, member strip, message stream, and composer all compile and keep current behavior.

---

### Task 4: Refine Message Bubble Density

**Files:**
- Modify: `chatroom_frontend/src/components/MessageItem.vue`

- [ ] **Step 1: Reduce message bubble noise while preserving sender distinction**

Target CSS:

```css
.message-row {
  gap: 10px;
  margin-bottom: 10px;
  padding: 0 4px;
}

.message-item {
  max-width: min(72%, 620px);
  padding: 10px 13px;
  border-radius: 18px;
  box-shadow: 0 6px 18px rgba(28, 18, 10, 0.05);
}

.message-item.mine {
  background: linear-gradient(135deg, #0f766e 0%, #0b5f58 100%);
}

.message-item:not(.mine) {
  background: rgba(255,255,255,0.96);
  border: 1px solid rgba(120, 104, 85, 0.1);
}
```

- [ ] **Step 2: Tighten continuation grouping**

Target CSS:

```css
.message-row.continuation {
  margin-top: -2px;
  margin-bottom: 8px;
}

.message-row.continuation .avatar {
  visibility: hidden;
  width: 0;
}
```

- [ ] **Step 3: Rework attachment blocks into compact message tiles**

Target CSS:

```css
.attachment-file {
  padding: 9px 12px;
  border-radius: 12px;
  background: rgba(17, 24, 39, 0.04);
}

.message-item.mine .attachment-file {
  background: rgba(255,255,255,0.16);
}

.attachment-image {
  border-radius: 14px;
  max-height: 280px;
}
```

- [ ] **Step 4: Soften timestamp and metadata emphasis**

Target CSS:

```css
.timestamp {
  font-size: 10px;
  margin-top: 5px;
  opacity: 0.58;
}

.message-item:hover .timestamp {
  opacity: 0.76;
}
```

- [ ] **Step 5: Verify message item changes**

Run:

```powershell
cd chatroom_frontend
npm run lint
npm run build
```

Expected: text messages, images, files, timestamps, and continuation groups still render correctly.

---

### Task 5: Final Chat-Specific Token Cleanup

**Files:**
- Modify: `chatroom_frontend/src/assets/theme.css`

- [ ] **Step 1: Add or normalize only the tokens needed by the chat redesign**

Target token block:

```css
:root {
  --chat-rail-width: 320px;
  --chat-shell-radius: 28px;
  --chat-panel-border: rgba(120, 104, 85, 0.1);
  --chat-panel-shadow: 0 18px 42px rgba(28, 18, 10, 0.06);
  --chat-surface-soft: rgba(255,255,255,0.92);
  --chat-surface-muted: rgba(245, 240, 234, 0.9);
}
```

- [ ] **Step 2: Replace repeated hard-coded chat values with the new tokens where it improves consistency**

Target usage examples:

```css
.conversation-rail,
.chat-window {
  border: 1px solid var(--chat-panel-border);
  box-shadow: var(--chat-panel-shadow);
}
```

- [ ] **Step 3: Run final verification for the full chat phase**

Run:

```powershell
cd chatroom_frontend
npm run lint
npm run build
```

Expected: the full chat redesign compiles cleanly and does not introduce new lint issues.

---

### Task 6: Browser Verification Pass

**Files:**
- Review only: `chatroom_frontend/src/views/Chat.vue`
- Review only: `chatroom_frontend/src/components/ChatWindow.vue`
- Review only: `chatroom_frontend/src/components/UserList.vue`
- Review only: `chatroom_frontend/src/components/GroupList.vue`
- Review only: `chatroom_frontend/src/components/MessageItem.vue`

- [ ] **Step 1: Start the frontend dev server**

Run:

```powershell
cd chatroom_frontend
npm run serve
```

Expected: local frontend is available at `http://localhost:8081`.

- [ ] **Step 2: Verify the direct-chat layout**

Check:

- selected conversation is obvious
- unread badges are easy to spot
- online state is visible but small
- header does not overpower the chat
- composer feels anchored

- [ ] **Step 3: Verify the group-chat layout**

Check:

- group member strip is calmer than the header
- group rows match the rail rhythm
- unread badges stay visible

- [ ] **Step 4: Verify mobile comfort**

Check at narrow width:

- rail is still usable
- header and composer do not consume most of the height
- message area still reads clearly

- [ ] **Step 5: Commit the phase**

Run:

```powershell
git add chatroom_frontend/src/views/Chat.vue chatroom_frontend/src/components/ChatWindow.vue chatroom_frontend/src/components/UserList.vue chatroom_frontend/src/components/GroupList.vue chatroom_frontend/src/components/MessageItem.vue chatroom_frontend/src/assets/theme.css docs/superpowers/specs/2026-06-25-chat-workbench-design.md docs/superpowers/plans/2026-06-25-chat-workbench-implementation.md
git commit -m "feat(chat): redesign chat workbench shell and message stage"
```

Expected: commit succeeds with only the intended chat-phase files.
