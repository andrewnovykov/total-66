References
- TRD: project_doc/docs/requirements/04-features/15-spam-reporting-moderation.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-15, SPEC-DATA

Status
- State: TODO
- Completed Date: —

Next Step
- Next PRD: project/sprint-3/PRD-1.md

---

### 2.3 Auto-Moderation
- [ ] Create moderation logic
  - [ ] Auto-hide goals with 3+ spam reports
  - [ ] Auto-hide posts with 3+ spam reports
  - [ ] Send to admin queue for review
- [ ] Add `moderation_status` field (clean, flagged, hidden, reviewed)
- [ ] Implement content filtering for hidden items
