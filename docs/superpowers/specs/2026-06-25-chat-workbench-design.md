# Chat Workbench Redesign

**Date:** 2026-06-25

**Scope:** `chatroom_frontend/src/views/Chat.vue` and its direct UI components

**Goal:** Rebuild the chat page into a clearer, denser, warmer collaboration workbench that follows the project rules in `AGENTS.md` without changing chat behavior.

---

## 1. Problem

The current chat page already has many good pieces.

It has unread badges.

It has online state.

It has group and direct chats.

It has a styled input area.

But the whole page still feels split.

Main issues:

- The sidebar, message area, empty states, and composer all compete for attention.
- The page uses the same visual volume everywhere.
- The message stage is not clearly stronger than the surrounding chrome.
- Contact rows and group rows are close in shape, but not in rhythm.
- Some decorative effects are louder than the information they surround.
- Mobile behavior is serviceable, but still feels like a compressed desktop page.

This makes the page feel styled, but not yet controlled.

---

## 2. Product Intent

This page is the highest-frequency workspace in ConnectHub.

Users should be able to answer these questions in under three seconds:

- Which conversation am I in?
- Who is online?
- Where is the unread activity?
- Is this a private chat or a group?
- Where do I type?
- Did my action go through?

The page should feel calm under load.

It should not feel decorative-first.

---

## 3. Design Direction

The redesign should read as a warm control surface.

Not a marketing page.

Not a card gallery.

Not a generic messenger clone.

Visual character:

- Warm off-white base
- Deep teal for active states
- Burnt orange only as support accent
- Soft grain and tint, not flat white
- Asymmetric balance, but stable reading lines
- Short, weighted motion

Behavior character:

- Active chat is obvious
- Unread signals are crisp
- Composer feels anchored
- Search feels integrated, not bolted on
- Empty states are quiet and useful

---

## 4. Structural Changes

### 4.1 Page Shell

The page keeps the current left navigation dock.

Inside the chat page itself, the main area becomes a two-zone layout:

- Conversation rail on the left
- Message stage on the right

The conversation rail should behave like a navigation surface.

The message stage should behave like the primary workspace.

The message stage must visually outweigh the rail.

### 4.2 Conversation Rail

The rail combines direct chats and groups into one controlled panel.

The tabs remain.

But the panel should feel like one conversation browser, not two stacked widgets.

Required qualities:

- Strong selected row state
- Quiet hover state
- Tighter vertical rhythm
- Better separation between name, preview, time, and unread
- Group rows and user rows should feel related

The divider between users and groups must become lighter and more functional.

It should stop feeling like a decorative split.

### 4.3 Message Stage

The right side becomes the dominant visual field.

It contains four layers:

1. Context header
2. Optional group member strip
3. Message stream
4. Composer

These layers should feel vertically locked.

The composer should read as the strongest action zone.

The message stream should read as the deepest content zone.

### 4.4 Header

The current header keeps:

- Avatar / group mark
- Conversation name
- Secondary meta
- Search

But it should be tightened.

For direct chats:

- Show username
- Show email only if it adds value
- Fallback text should stay short

For groups:

- Show group name
- Show member count

Search should become quieter.

It is a utility.

Not a hero element.

### 4.5 Group Members Bar

The member strip stays.

But it should feel lighter.

It is reference information.

Not a second header.

Member chips should be smaller, calmer, and easier to scan in a row.

---

## 5. Message Design

### 5.1 Bubble Hierarchy

Own messages and incoming messages should keep different shapes.

But the contrast must be cleaner:

- Own messages: solid, confident, brand-led
- Incoming messages: soft surface, strong text, low decoration

Incoming messages should not feel weak.

They should feel neutral and readable.

### 5.2 Continuation Logic

Message grouping already exists.

The redesign should make grouping more obvious:

- Less vertical noise between continuation messages
- Reduced avatar repetition
- Cleaner edge radius logic

This improves scan speed in long chats.

### 5.3 Metadata

Timestamp and delivery state should stay visible but secondary.

They should never compete with message text.

Hover emphasis can stay subtle.

### 5.4 Attachments

Image and file blocks should feel more intentional.

Files should read like compact action tiles.

Images should remain light and fast.

Attachment cards must not visually break message flow.

### 5.5 Empty State

The empty state should stay friendly.

But it must stop feeling like a promo card.

Target tone:

- Quiet
- Useful
- Short

The CTA can remain.

It should not dominate the center of the page.

---

## 6. State System

These states must become the clearest signals on the page:

- Active conversation
- Online / offline
- Unread count
- New messages while scrolled up
- Jump to latest
- Loading
- Empty
- Send success / failure toast

Rules:

- Active state uses deep teal and structural emphasis
- Unread count uses warm danger contrast
- Online state stays small and trustworthy
- Loading uses low-noise skeletons
- Banners should feel actionable, not flashy

---

## 7. Motion Rules

Motion stays in the redesign.

But it must be trimmed.

Keep:

- Message enter transitions
- Hover lift on actionable controls
- Small tab transitions
- Composer focus feedback

Reduce:

- Repeated pulse effects
- Oversized glow feelings
- Decorative motion on non-critical elements

All motion should use custom cubic-bezier easing.

No `ease-in-out`.

---

## 8. Responsive Rules

### Desktop

Desktop is the main target.

The conversation rail should remain readable.

The composer should feel stable.

The message stream should get the most width.

### Tablet

The page can keep two zones if space allows.

But the rail must slim down without losing unread visibility.

### Mobile

Mobile should stop feeling like a squeezed desktop split view.

Required adjustments:

- Reduce rail height noise
- Tighten row spacing
- Keep composer reachable
- Prevent the header and composer from eating too much vertical space

The first mobile pass should improve comfort, not redesign navigation logic.

No route or behavior changes in phase 1.

---

## 9. Implementation Boundaries

This phase is visual and structural.

It should not change:

- WebSocket behavior
- Message sending logic
- Read/unread business rules
- Route structure
- Data fetching contracts

This phase may change:

- Template grouping
- Class naming
- CSS structure
- Visual hierarchy
- Small utility text

---

## 10. Files In Scope

Primary files:

- `chatroom_frontend/src/views/Chat.vue`
- `chatroom_frontend/src/components/ChatWindow.vue`
- `chatroom_frontend/src/components/UserList.vue`
- `chatroom_frontend/src/components/GroupList.vue`
- `chatroom_frontend/src/components/MessageItem.vue`

Possible shared token cleanup:

- `chatroom_frontend/src/assets/theme.css`

No backend files are in scope for this phase.

---

## 11. Success Criteria

The redesign succeeds if:

- The current conversation is obvious at a glance
- The rail feels like one system
- The message area feels calmer and denser
- The composer feels anchored
- Unread and online states are easier to spot
- Empty and loading states feel lighter
- Desktop looks more intentional
- Mobile feels less cramped

The redesign fails if:

- The page becomes prettier but slower to scan
- Active and unread states get weaker
- Search or composer lose clarity
- The rail becomes more decorative than useful
- The message stage starts to feel like a showcase

---

## 12. Recommended Execution Order

1. Rebuild page shell and hierarchy in `Chat.vue`
2. Tighten `ChatWindow.vue` header, message field, and composer framing
3. Unify conversation row rhythm in `UserList.vue` and `GroupList.vue`
4. Refine bubble density and attachment styling in `MessageItem.vue`
5. Do a light token cleanup only where the chat page still depends on conflicting values

---

## 13. Phase 1 Summary

Phase 1 does not try to reinvent chat behavior.

It establishes the visual and structural standard for the rest of the app.

If this page becomes stable, the same language can be extended to:

- Home
- Events
- Admin

This is why `Chat` goes first.
