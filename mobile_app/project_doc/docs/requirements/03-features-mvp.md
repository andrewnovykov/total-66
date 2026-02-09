# MVP Features

## Feature 1: Goals (Structured Goals with Phases & Steps)

### User Story

As a regular user, I want to create a goal with phases and steps, so that I can execute a structured plan and track real progress.

### Priority

🔴 Must Have (MVP)

### Detailed Flow

1. User opens My Goals and chooses Create Goal
2. System shows goal form with title, description, category, visibility, due date, and phases/steps
3. User defines phases and steps, then submits
4. System creates the goal, initializes progress, and shows the goal detail page
5. Result: Goal appears in My Goals with progress tracking and a goal feed

### Inputs

| Field          | Type     | Required | Validation                         |
| -------------- | -------- | -------- | ---------------------------------- |
| title          | text     | Yes      | Non-empty                          |
| description    | text     | No       | —                                  |
| image          | file/url | No       | —                                  |
| category_id    | id       | Yes      | Must be an admin-defined category  |
| visibility     | enum     | Yes      | public / friends / private         |
| status         | enum     | Yes      | active / frozen / completed / failed |
| due_date       | date     | No       | Valid date                         |
| phases         | list     | Yes      | At least 1 phase                   |
| steps          | list     | Yes      | At least 1 step per phase          |

### Outputs

- Goal detail page with phases/steps, progress bar, and goal feed
- Goal appears in My Goals list

### Business Rules

- Goals can be public, friends-only, or private
- Frozen goals cannot be edited until unfrozen
- Failed goals require a failure reason

### Edge Cases

- What if user sets visibility to friends-only? → Only accepted friends can view
- What if goal is frozen? → Editing is blocked until unfrozen

---

## Feature 2: Challenges (Predefined + Custom with Scheduling)

### User Story

As a regular user, I want to join an admin challenge or create my own challenge with scheduled tasks, so that I can follow structured programs or build habit routines.

### Priority

🔴 Must Have (MVP)

### Detailed Flow

1. User opens Challenges
2. System shows predefined challenges and option to create a custom challenge
3. User joins a predefined challenge or defines a custom challenge with a schedule
4. System enrolls the user and creates the active challenge instance
5. Result: Challenge appears in My Goals/Challenges and counts toward active items

### Inputs

| Field          | Type   | Required | Validation                                           |
| -------------- | ------ | -------- | ---------------------------------------------------- |
| challenge_type | enum   | Yes      | predefined / custom                                  |
| title          | text   | Yes (custom) | Non-empty                                        |
| description    | text   | No       | —                                                    |
| schedule       | enum/list | Yes (custom) | daily / twice-week / every-other-day / Mon–Fri / custom weekdays |
| phases/steps   | list   | Yes (predefined) | Template-defined, read-only                    |

### Outputs

- Challenge appears in the user’s active items list
- Challenge detail shows schedule and progress

### Business Rules

- Predefined challenges are template-locked (phases/steps not editable)
- Active challenges count toward the max 3 active items limit

### Edge Cases

- What if user already has 3 active items? → Cannot activate a new challenge
- What if user tries to edit a predefined challenge? → Disallowed

---

## Feature 3: Coach Center (Group Goals + Dashboard)

### User Story

As a coach, I want to create a group goal template and enroll people, so that each participant gets their own goal instance and I can track their progress.

### Priority

🔴 Must Have (MVP)

### Detailed Flow

1. Coach opens Coach Center and creates a group goal template
2. Coach adds participants and starts the group goal
3. System generates individual goal instances for each participant
4. Participants complete steps and post updates
5. Result: Coach dashboard shows progress, activity, and at-risk users

### Inputs

| Field            | Type | Required | Validation                       |
| ---------------- | ---- | -------- | -------------------------------- |
| template_title   | text | Yes      | Non-empty                        |
| template_phases  | list | Yes      | At least 1 phase                 |
| template_steps   | list | Yes      | At least 1 step per phase        |
| participants     | list | Yes      | Valid users                      |

### Outputs

- Coach dashboard with participant list, status, progress, last activity, and commitment heatmap
- Individual participant goals created from the template

### Business Rules

- Coach can create templates and enroll participants
- Coach cannot edit participant progress; participants update via steps/posts

### Edge Cases

- What if a participant is removed before start? → No goal instance created
- What if a participant fails to update? → Coach sees at-risk indicator
