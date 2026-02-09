References

- TRD: project_doc/docs/requirements/04-features/11-my-goals.md
- TRD: project_doc/docs/design/pages/09-my-goals.md
- TRD: project_doc/docs/specifications/user-flow.md
- TRD IDs: REQ-11, DESIGN-09, SPEC-FLOW

Status

- State: DONE
- Completed Date: 2026-02-07

Next Step

- Next PRD: project/sprint-0/PRD-5.md

---

### 0.4 My Goals Dashboard

- [x] Unified dashboard for goals, challenges, group goal instances
- [x] Status transitions (active / frozen / completed / failed)
- [x] Edit/delete own items (with restrictions)
- [x] BUG-8: Removed /goals route (now only /my-goals and /all-goals)

#### Implementation Details

**Unified Dashboard** (`/my-goals`):
- Goals section with filter pills (All/Active/Completed)
- Challenges section with filter pills (All/Active/Completed/Failed)
- Challenge cards show status, type, progress, dates, days remaining
- Sidebar shows combined overview stats (goals + challenges count)
- Quick links to My Challenges, Browse All Goals, Browse Challenges, Goal Categories

**Goal Quick Actions** (per card):
- Edit link to `/goals/:id/edit`
- Freeze/Unfreeze toggle (active/frozen goals only)
- Fail button with confirmation (active/paused/frozen goals)
- Delete button with confirmation (soft delete, moves to Deleted Goals section)

**BUG-8 Fix**:
- Removed `live "/goals", GoalLive.Index` route
- Updated `goal_live/show.ex` and `goal_live/edit.ex` to navigate to `/my-goals`
- Updated navigation role tests to use `/all-goals`
