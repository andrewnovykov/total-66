References
- TRD: project_doc/docs/requirements/04-features/05-challenges.md
- TRD: project_doc/docs/design/pages/04-challenges.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-05, DESIGN-04, SPEC-DATA

Status
- State: IN-PROGRESS

Next Step
- Next PRD: project/sprint-0/PRD-4.md

---

### 0.3 Challenges (Predefined + Custom)

#### Phase 1 — Core (DONE)
- [x] Admin predefined challenge templates (phases/steps)
- [x] User-created challenges with task schedules
- [x] Challenge visibility rules
- [x] Template vs Personal challenge split (is_template, template_id)
- [x] Start challenge from template (creates personal copy)
- [x] Index page: Templates tab + My Challenges tab
- [x] Challenge categories (separate from goal categories)

#### Phase 2 — Personal Challenge Experience (DONE)
- [x] Remove "Leave" from personal challenges; add "Fail Challenge"
- [x] Add :failed status to Challenge and ChallengeParticipant
- [x] Remove Participants section from personal challenges (solo)
- [x] Overall progress: day X of Y with progress bar
- [x] Daily progress: today's scheduled tasks with done/failed status

#### Phase 3 — Daily Check-in System (DONE)
- [x] DailyCheckIn schema (day_number, task summary, note, status)
- [x] "Finish Day X" button to submit daily check-in
- [x] Mark each task as done/failed before finishing day
- [x] One check-in per day per challenge (unique constraint)
- [x] After check-in: tasks for that day become read-only

#### Phase 4 — Challenge Feed (PARTIAL)
- [x] Challenge feed showing daily check-in posts
- [ ] Comments on daily check-ins (polymorphic via target_type)
- [ ] Reactions (likes) on daily check-ins
- [x] Feed visibility follows challenge visibility
