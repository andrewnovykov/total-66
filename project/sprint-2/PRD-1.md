References
- TRD: project_doc/docs/requirements/04-features/15-spam-reporting-moderation.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-15, SPEC-DATA

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-2/PRD-2.md

---

### 2.1 Spam Reporting System
- [x] Create `reports` table (goal_id, post_id, user_id, reason, created_at)
- [x] Add red flag icon to every goal
- [x] Add red flag icon to every post
- [x] Implement reporting functionality
  - [x] Report modal with reason selection
  - [x] Prevent duplicate reports from same user
  - [x] Track report counts per goal/post
  - [x] Auto-hide content when report count reaches threshold (3)
  - [x] Filter hidden content from public views
  - [x] REST API endpoints (POST /api/goals/:id/report, POST /api/posts/:id/report)
  - [x] Comprehensive test coverage (37 tests)
