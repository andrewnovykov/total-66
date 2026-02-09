References
- TRD: project_doc/docs/requirements/04-features/15-spam-reporting-moderation.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-15, SPEC-DATA

Status
- State: TODO
- Completed Date: —

Next Step
- Next PRD: project/sprint-2/PRD-2.md

---

### 2.1 Spam Reporting System
- [ ] Create `reports` table (goal_id, post_id, user_id, reason, created_at)
- [ ] Add red flag icon to every goal
- [ ] Add red flag icon to every post
- [ ] Implement reporting functionality
  - [ ] Report modal with reason selection
  - [ ] Prevent duplicate reports from same user
  - [ ] Track report counts per goal/post
