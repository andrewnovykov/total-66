# Phase 2: Spam Reporting & Moderation

### 2.1 Spam Reporting System
- [ ] Create `reports` table (goal_id, post_id, user_id, reason, created_at)
- [ ] Add red flag icon to every goal
- [ ] Add red flag icon to every post
- [ ] Implement reporting functionality
  - [ ] Report modal with reason selection
  - [ ] Prevent duplicate reports from same user
  - [ ] Track report counts per goal/post

### 2.2 Bug Reporting System
- [ ] Create `bug_reports` table (user_id, page_name, description, status, created_at)
- [ ] Add bug report icon to all pages
- [ ] Implement bug reporting functionality
  - [ ] Bug report modal with page name selection
  - [ ] Description field for bug details
  - [ ] Track bug report status (open, in_progress, resolved)
- [ ] Admin dashboard integration for bug reports
  - [ ] List all bug reports
  - [ ] Filter by status and page
  - [ ] Mark bugs as resolved

### 2.3 Auto-Moderation
- [ ] Create moderation logic
  - [ ] Auto-hide goals with 3+ spam reports
  - [ ] Auto-hide posts with 3+ spam reports
  - [ ] Send to admin queue for review
- [ ] Add `moderation_status` field (clean, flagged, hidden, reviewed)
- [ ] Implement content filtering for hidden items
