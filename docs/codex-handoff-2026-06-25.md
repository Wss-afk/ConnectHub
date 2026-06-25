# ConnectHub Frontend Handoff

Last updated: `2026-06-25`
Branch: `main`

## Goal

Continue the frontend cleanup and redesign work under the current `AGENTS.md` direction without redoing discovery.

This project is not a marketing site.

It is a collaboration workbench.

The design rule is:

- efficiency first
- personality second
- decoration must never hide information

## Read First

- [AGENTS.md](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/AGENTS.md)
- [chat workbench design](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/docs/superpowers/specs/2026-06-25-chat-workbench-design.md)
- [chat workbench implementation plan](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/docs/superpowers/plans/2026-06-25-chat-workbench-implementation.md)

## What Was Already Done

### 1. `AGENTS.md` was rewritten for this repo

It now frames ConnectHub as:

- chat
- schedule/tasks
- status visibility
- admin backoffice

Key consequence:

- anti-template style is welcome
- but the UI must still read like a high-frequency work tool

### 2. Chat area got a full first-pass redesign

Files already touched:

- [Chat.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Chat.vue)
- [ChatWindow.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/components/ChatWindow.vue)
- [UserList.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/components/UserList.vue)
- [GroupList.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/components/GroupList.vue)
- [MessageItem.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/components/MessageItem.vue)

Status:

- shell/layout updated
- conversation rail updated
- message area updated
- message bubble density tightened
- attachments styled

### 3. Homepage got a strong first-pass redesign

Primary file:

- [Home.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Home.vue)

Current homepage state:

- welcome band is shorter than before
- top-right cards are now:
  - live local time with seconds
  - faux local weather card
- scratchpad section was removed from the template
- homepage right column now aims to keep everything visible without stretching the page

### 4. Preview mode was added for frontend-only work

Files:

- [main.js](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/main.js)
- [previewAuth.js](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/utils/previewAuth.js)

Use these URLs during frontend-only work:

- user preview: `http://localhost:3000/login?preview=user`
- admin preview: `http://localhost:3000/login?preview=admin`
- turn preview off: `http://localhost:3000/login?preview=off`

Rules:

- preview auth only works in development
- production build ignores it
- no backend is required to enter protected routes

### 5. Old compile blockers were fixed

These were not design work, just necessary unblockers:

- [Home.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Home.vue)
  - fixed `clearNote()` brace issue
- [App.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/App.vue)
- [AppDock.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/components/AppDock.vue)
- [Login.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Login.vue)
  - duplicate SFC blocks were removed

## Current Known State

### Verified

These commands were run successfully multiple times during this session:

- `npm run lint`
- `npm run build`
- targeted lint on `Home.vue`
- targeted lint on chat files

Expected warnings still remain:

- `browserslist` / `caniuse-lite` age warning
- webpack asset size warning

These are not blockers for ongoing UI work.

### Important debt still sitting in the code

#### `Home.vue` still contains old note logic

The scratchpad template section was removed.

But the following are still likely present and now partially dead:

- `quickNote`
- `saveStatus`
- `saveNote()`
- `clearNote()`
- note-related `localStorage` reads in `mounted()` / `watch`
- old scratchpad-related styles

This is a good cleanup task.

Do it carefully.

Do not break the current build while removing it.

#### `Home.vue` is still a layered file

It contains:

- older base styles
- later override styles
- mixed historical UI language

Further edits should be surgical unless you intentionally do a cleanup pass.

#### Weather card is decorative, not real

The top-right weather card is local/fake.

It changes by time and season heuristics.

It does not call a weather API.

If you change it, keep the same principle unless the user explicitly asks for live weather.

## Recommended Next Steps

### Priority 1

Clean `Home.vue` after scratchpad removal.

Specifically:

- remove dead note state
- remove dead note methods
- remove dead note watchers/mounted code
- remove dead note CSS

Goal:

- homepage file becomes easier to reason about
- page height stays compact

### Priority 2

Redesign [Events.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Events.vue).

Why next:

- it is a core workbench page
- it is still visually behind Chat/Home
- calendar hierarchy, day details, assignee clarity still need tightening

Suggested focus:

- month calendar readability
- selected day hierarchy
- event detail density
- creator / assignee visibility
- reduce generic dashboard feel

### Priority 3

Unify [Admin.vue](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/views/Admin.vue) and child admin pages with the current language.

Constraint:

- admin should feel stricter and calmer than chat/home
- still not default Bootstrap-looking

### Priority 4

If the user keeps pushing visual polish:

- consolidate surviving tokens into [theme.css](/C:/Users/wang1/Desktop/proyectos/TFG21/CONNECTHUB/chatroom_frontend/src/assets/theme.css)
- gradually reduce giant single-file overrides

Do not start here.

The core pages matter more.

## Working Rules For The Next Codex

- Respect `AGENTS.md` above personal taste.
- Do not bring back purple / indigo SaaS styling.
- Do not use centered hero logic on workbench pages.
- Preserve information priority over aesthetics.
- Prefer one-screen usefulness on desktop.
- Use `apply_patch` for manual edits.
- Re-run `npm run build` before claiming completion.

## Suggested First Move

If continuing from here, start with:

1. read `Home.vue`
2. remove dead scratchpad logic
3. run `npx vue-cli-service lint src/views/Home.vue`
4. run `npm run build`
5. then move to `Events.vue`

