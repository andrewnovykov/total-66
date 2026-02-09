References
- TRD: project_doc/docs/requirements/04-features/04-goals.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-04, SPEC-DATA

Status
- State: TODO
- Completed Date: —

Next Step
- Next PRD: project/sprint-1/PRD-3.md

---

### 1.2 Goal Status Management
- [ ] Add `status` field to goals table (active, frozen, completed, failed, deleted)
- [ ] Implement goal freezing functionality
  - [ ] Add "Freeze Goal" button for goal owners
  - [ ] Disable editing/posting when goal is frozen
  - [ ] Add "Unfreeze Goal" button with confirmation
- [ ] Create goal deletion functionality
  - [ ] Soft delete goals (mark as deleted, don't remove from DB)
  - [ ] Only goal owners can delete their goals
  - [ ] Add confirmation dialog for deletion
