# Feature 5: Challenges (Menu + Two Challenge Types)

## User Story
"As a user, I want to choose challenges so that I can follow structured programs or build my own habit system."

## Challenge Type A: Predefined (Admin-created)

### Structure
- Phases → Steps (defined by admin)

### User Can
- Join
- Complete steps
- Progress through phases

### User Cannot
- Edit template structure

## Challenge Type B: User-created Challenge

### Structure
- Daily tasks + schedule per task

### Task Schedule Options
- Every day
- Twice a week
- Every other day
- Mon–Fri
- Custom weekdays (e.g., Mon/Wed/Fri)

---

## Template vs Personal Challenge

Challenges exist in two forms: **Templates** and **Personal Challenges**.

### Templates (is_template = true)
- Read-only blueprints that users browse but cannot join, leave, or track progress on
- **Official templates**: Admin-created, type `:predefined`, defined by `duration_days`
- **Community templates**: User-shared, type `:custom`, defined by `start_date`/`end_date`
- Show "People who started" count (number of derived personal challenges)
- No participants section, no feed, no progress tracking

### Personal Challenges (is_template = false)
- Created via "Start Challenge" from a template (copies phases/steps/tasks)
- Solo experience — no participants section, no "Leave" button
- Has own `start_date`/`end_date` calculated from template's `duration_days`
- References parent template via `template_id`
- Includes progress tracking, daily check-ins, and a challenge feed

---

## Fail Challenge

Personal challenges use "Fail Challenge" instead of "Leave".

### Behavior
- Only available on personal challenges (not templates)
- Sets challenge status to `:failed`
- Sets participant status to `:failed`
- Optionally records `failure_reason` (text field)
- Records `failed_at` timestamp
- Challenge remains visible in "My Challenges" with a "Failed" badge
- Failed challenges cannot be restarted — user must start a new one from the template

### UI
- Red "Fail Challenge" button replaces any "Leave" button on personal challenges
- Confirmation modal: "Are you sure you want to fail this challenge? This cannot be undone."
- Optional text field for failure reason in the confirmation modal

---

## Daily Check-in System

Each personal challenge has a daily check-in flow tied to the challenge's scheduled tasks.

### Flow
1. User opens their personal challenge
2. System shows "Today's Tasks" — the tasks scheduled for today based on the task schedule
3. User marks each task as **done** or **failed**
4. User clicks "Finish Day X" button (where X = current day number)
5. System creates a `DailyCheckIn` record
6. The check-in becomes a feed post in the challenge feed
7. Tasks for that day become read-only after check-in

### Day Number Calculation
- `day_number = Date.diff(today, challenge.start_date) + 1`
- Day 1 is the challenge start date

### Constraints
- One check-in per day per challenge (enforced by unique constraint on `[participant_id, completed_date]`)
- Cannot submit a check-in for a future day
- Cannot submit a check-in for a past day (must be today)
- All tasks for the day must be marked (done or failed) before finishing

### DailyCheckIn Record
- `day_number`: which day of the challenge
- `completed_date`: the calendar date
- `total_tasks`: how many tasks were scheduled
- `completed_tasks`: how many marked done
- `failed_tasks`: how many marked failed
- `skipped_tasks`: how many were not addressed
- `note`: optional user reflection/comment about the day

---

## Challenge Feed

Every personal challenge has a feed showing the user's daily check-in history.

### Feed Items
- Each `DailyCheckIn` is displayed as a feed post
- Shows: day number, task summary (e.g., "3/4 tasks completed"), optional note
- Ordered by newest first (most recent check-in at top)

### Social Features on Check-ins
- Users can **comment** on daily check-ins (polymorphic via `target_type = 'daily_check_in'`)
- Users can **react** (like) to daily check-ins (polymorphic via `target_type = 'daily_check_in'`)
- Comments and reactions use the existing polymorphic Reaction and Comment tables

### Visibility
- Feed visibility follows the challenge's visibility setting
- Public challenges: feed visible to everyone
- Friends-only challenges: feed visible to accepted friends
- Private challenges: feed visible only to the owner

---

## Rules
- Active challenges count toward "max 3 active items"
- Predefined challenge steps/phases are read-only to participants
- User-created challenge tasks are editable by creator
- Personal challenges are solo — no participants section
- Personal challenges show "Fail Challenge" not "Leave"
- One daily check-in per day per challenge
- Failed challenges remain visible in My Challenges with a failed badge
- Failed challenges cannot be restarted
- Daily check-ins are visible in the challenge feed
- Templates cannot be joined/left — only "Start Challenge" to create a personal copy
