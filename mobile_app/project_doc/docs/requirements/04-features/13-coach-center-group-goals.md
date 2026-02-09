# Feature 13: Coach Center + Group Goals (Coach Role)

## User Story
“As a coach, I want to create a group goal and enroll people so each participant gets their own goal instance and I can track progress.”

## Group Goal (Coach Template)

### Coach Defines
- Title
- Description
- Category
- Visibility (group-only)
- Phases + Steps (template structure)
- Optional due date/duration

### Coach Actions
- Create template (draft)
- Add participants
- Start group goal

### On Start
Each participant receives:
- Their own goal instance copied from template
- Status = Active (unless blocked by 3-active rule)

## Coach Dashboard
Coach can see:
- Group goal list
- Participant list per group goal
- Per user: status, progress, last activity date, commitment heatmap, “at risk” indicators

## Rules
- Coach cannot edit participant progress
- Participant cannot edit template structure (only progress + posts)
- Participant visibility for outsiders remains controlled by participant
- Coach always sees progress for the group goal context
