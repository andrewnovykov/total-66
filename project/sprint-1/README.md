# Sprint 1: Security, Ownership & Social Connections

## Sprint Overview
This sprint focuses on security controls, ownership validation, and the social connections management system.

---

## PRDs in This Sprint

### PRD-1: Goal & Post Ownership
**Status:** TODO
**File:** `project/sprint-1/PRD-1.md`

Implement ownership validation ensuring only goal owners can edit goals/steps and only post authors can edit/delete their posts.

### PRD-2: Goal Status Management
**Status:** DONE
**File:** `project/sprint-1/PRD-2.md`

Add goal status field (active, frozen, completed, failed, deleted) with freeze/unfreeze and soft delete functionality.

### PRD-3: Goal Failure System
**Status:** TODO
**File:** `project/sprint-1/PRD-3.md`

Implement goal failure functionality with required failure reason, timestamp tracking, and failure history display.

### PRD-4: Connections Manager
**Status:** DONE
**File:** `project/sprint-1/PRD-4.md`
**Completed:** 2025-02-05

Central hub for managing social relationships:
- Following/Followers management
- Friends list management
- Friend request handling (incoming/sent)
- Stats summary with counts

---

## Sprint Progress

| PRD | Feature | Status |
|-----|---------|--------|
| PRD-1 | Goal & Post Ownership | TODO |
| PRD-2 | Goal Status Management | DONE |
| PRD-3 | Goal Failure System | TODO |
| PRD-4 | Connections Manager | DONE |

---

## Key Deliverables

### Security & Ownership
- [ ] Server-side ownership validation for goals
- [ ] Server-side ownership validation for posts
- [ ] Comprehensive test coverage for ownership

### Goal Management
- [x] Goal status field with all status values
- [x] Freeze/unfreeze functionality
- [x] Soft delete functionality
- [ ] Goal failure with required reason

### Social Connections
- [x] `/connections` page with tabbed interface
- [x] Following tab with unfollow action
- [x] Followers tab with remove action
- [x] Friends tab with remove friend action
- [x] Requests tab with accept/decline/cancel actions
- [x] Stats summary bar with counts

---

## Dependencies
- Phase 0 core features must be complete
- User authentication system
- Basic goal CRUD operations
- Friendship/follow database schemas

---

## Related Documentation
- `project_doc/docs/requirements/04-features/04-goals.md`
- `project_doc/docs/requirements/04-features/08-social-graph.md`
- `project_doc/docs/design/pages/14-connections.md`
