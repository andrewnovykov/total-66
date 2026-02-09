Coach-Driven Goal Programs

1. Product Overview

GoalHub is a goal-oriented social platform where:
• Coaches create goal templates
• Coaches run goal programs (groups) based on those templates
• Users join programs and get their own personal goal instance
• Coaches track, manage, and guide progress at scale

The system is template-driven, not shared-goal execution.

⸻

2. Core Concepts (Data Model)

2.1 GoalTemplate

Blueprint created by a coach.

Fields
• id
• title
• description
• duration (days/weeks)
• steps[] (ordered)
• rules / expectations
• visibility (private / public / coach-only)
• createdBy (coachId)

Notes
• Immutable after program starts (versioned if edited)
• Reusable across multiple groups

⸻

2.2 GoalProgram (Group)

A coach-run instance of a GoalTemplate.

Fields
• id
• goalTemplateId
• coachId
• name (e.g. “January Focus Sprint”)
• startDate
• endDate
• status (draft / active / completed / archived)
• maxParticipants (optional)

Purpose
• Organizational container
• Coach management boundary
• Analytics scope

⸻

2.3 UserGoal

A personal execution of a GoalTemplate by a user.

Fields
• id
• userId
• goalTemplateId
• goalProgramId (nullable)
• progress
• stepStatus[]
• status (active / failed / completed / removed)
• createdAt

Rules
• Each user has their own UserGoal
• Progress is never shared between users
• Coach can see all UserGoals inside their programs

⸻

2.4 Coach

A user with elevated permissions.

Abilities
• Create templates
• Create programs
• Add/remove participants
• View participant progress
• Send feedback
• Archive programs

⸻

3. User Roles

Coach
• Creates templates
• Runs programs
• Oversees many users at once

Participant (User)
• Joins programs
• Works on personal goals
• Reports progress
• Receives feedback

⸻

4. Core User Flows

⸻

4.1 Coach: Create Goal Template

Steps 1. Coach clicks “Create Goal Template” 2. Defines:
• Goal title
• Description
• Steps (ordered)
• Duration 3. Saves template

Acceptance Criteria
• Template saved
• Editable only before being used in a program
• Version locked once program starts

⸻

4.2 Coach: Create Goal Program (Group)

Steps 1. Coach selects GoalTemplate 2. Creates GoalProgram 3. Sets:
• Name
• Dates
• Max users (optional) 4. Program starts in draft

Acceptance Criteria
• Program exists
• No users yet
• Template locked for this program

⸻

4.3 Coach: Add Participants

Steps 1. Coach invites users OR approves join requests 2. For each user:
• System creates UserGoal from template
• Links it to GoalProgram

Acceptance Criteria
• UserGoal created
• User sees goal in “My Goals”
• Coach sees user in program dashboard

⸻

4.4 User: Work on Goal

Steps 1. User opens UserGoal 2. Marks steps as done 3. Adds optional notes 4. Progress auto-updates

Acceptance Criteria
• Progress saved
• Visible to coach
• Private from other users

⸻

4.5 Coach: Monitor Progress

Coach Center View
• Program list
• For each program:
• Participants
• Progress %
• Failed / stuck users
• Completed users

Acceptance Criteria
• Real-time visibility
• Filterable by status

⸻

4.6 Coach: Send Feedback

Definition
Feedback = private comment tied to a UserGoal or step

Capabilities
• Comment on:
• Whole goal
• Specific step
• Optional suggestions

Visibility
• Only coach + that user
• Not public
• Not visible to other participants

⸻

4.7 Coach: Remove Participant

Steps 1. Coach removes user from program 2. System updates UserGoal:
• status → removed
• programId → null (optional)

Result
• User loses coach tracking
• Historical data preserved
• User can reuse template independently

⸻

4.8 User: Fail Program → Copy Template

Scenario 1. User fails or exits program 2. User clicks “Reuse Template” 3. New UserGoal created
• No coach
• No group
• Fully private

Acceptance Criteria
• Coach has no visibility
• User keeps template benefit
• New goal independent

⸻

5. Coach Center — UI Requirements

5.1 Coach Dashboard
• Programs list
• Active users count
• Completion rate
• Alerts (inactive users)

⸻

5.2 Program Page
• Template summary
• Participant table:
• Name
• Progress
• Status
• Last activity
• Actions:
• Message user
• Remove user
• Archive program

⸻

5.3 Template Library
• All templates created by coach
• Usage count
• Clone / archive

⸻

6. Permissions Matrix

Action Coach User
Create template ✅ ❌
Create program ✅ ❌
Join program ❌ ✅
View others’ progress ❌ ❌
View own progress ❌ ✅
Remove participant ✅ ❌
Copy template ❌ ✅

⸻

7. Non-Goals (Explicit)
   • ❌ Shared progress toward one common goal
   • ❌ Public progress comparison
   • ❌ Coach editing user progress
   • ❌ Social feed inside programs (v1)

⸻

8. Key Design Principle

Templates scale. Goals stay personal. Coaches oversee, not execute.
