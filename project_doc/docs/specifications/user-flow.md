# User Flows

> This document describes the step-by-step journeys users take through HeadsUp.
> Each flow shows what the user does and what the system does in response.

---

## Flow 1: Guest Browsing

**Goal:** Let a guest explore public content and funnel to login for interactions.

**Actors:** Guest (not logged in)

**Entry Points:** `/`

```
STEP 1: Land on Home
├── 👤 USER: Visits Home (/)
├── 💻 SYSTEM: Loads public Home content
├── 👁️ USER SEES: Trending Goals, Popular Groups, Spotlight Users
└── ➡️ NEXT: Step 2

STEP 2: Browse Sections
├── 👤 USER: Scrolls through sections
├── 💻 SYSTEM: Lazily loads more cards as needed
├── 👁️ USER SEES: Goal cards, group tiles, user spotlights
└── ➡️ NEXT: Step 3

STEP 3: Open Public Goal
├── 👤 USER: Clicks a public goal
├── 💻 SYSTEM: Loads goal detail (public view)
├── 👁️ USER SEES: Goal header, phases/steps, posts, reactions
└── ➡️ NEXT: Step 4

STEP 4: Attempt Interaction
├── 👤 USER: Clicks like/comment
├── 💻 SYSTEM: Detects guest, redirects to login
├── 👁️ USER SEES: Login page with redirect back
└── ➡️ NEXT: Flow ends
```

---

## Flow 2: Register → Create First Goal

**Goal:** New user registers and creates their first goal.

**Actors:** Visitor → Regular user

**Entry Points:** `/register`

```
STEP 1: Register
├── 👤 USER: Completes registration form (/register)
├── 💻 SYSTEM: Creates account and logs in
├── 👁️ USER SEES: Redirect to Home
└── ➡️ NEXT: Step 2

STEP 2: Navigate to My Goals
├── 👤 USER: Opens My Goals (/my-goals)
├── 💻 SYSTEM: Loads personal goals list
├── 👁️ USER SEES: My Goals dashboard
└── ➡️ NEXT: Step 3

STEP 3: Start Goal Creation
├── 👤 USER: Clicks Create → Goal
├── 💻 SYSTEM: Opens goal creation form
├── 👁️ USER SEES: Goal form fields
└── ➡️ NEXT: Step 4

STEP 4: Enter Goal Details
├── 👤 USER: Enters title, category, visibility, due date
├── 💻 SYSTEM: Validates inputs
├── 👁️ USER SEES: Form with validation feedback
└── ➡️ NEXT: Step 5

STEP 5: Add Phases and Steps
├── 👤 USER: Adds phases and steps
├── 💻 SYSTEM: Updates preview/progress
├── 👁️ USER SEES: Structured plan
└── ➡️ NEXT: Step 6

STEP 6: Save Goal
├── 👤 USER: Clicks Save
├── 💻 SYSTEM: Creates goal, sets status Active if under 3-item limit
├── 👁️ USER SEES: Goal detail page with Active status
└── ➡️ NEXT: Flow ends
```

---

## Flow 3: Create Custom Challenge with Scheduled Tasks

**Goal:** User creates a custom challenge with scheduled tasks.

**Actors:** Regular user

**Entry Points:** Create menu

```
STEP 1: Start Custom Challenge
├── 👤 USER: Selects Create → Challenge → Create my own
├── 💻 SYSTEM: Opens custom challenge form
├── 👁️ USER SEES: Challenge task builder
└── ➡️ NEXT: Step 2

STEP 2: Add Tasks
├── 👤 USER: Adds tasks:
│   • "Gym" schedule = Mon/Wed/Fri
│   • "Stretch" schedule = daily
├── 💻 SYSTEM: Validates schedules
├── 👁️ USER SEES: Task list with schedule labels
└── ➡️ NEXT: Step 3

STEP 3: Save Challenge
├── 👤 USER: Clicks Save
├── 💻 SYSTEM: Creates challenge, sets Active if under 3-item limit
├── 👁️ USER SEES: Challenge detail with schedules
└── ➡️ NEXT: Flow ends
```

---

## Flow 4: Join Predefined Challenge

**Goal:** User joins an admin-created challenge.

**Actors:** Regular user

**Entry Points:** `/challenges`

```
STEP 1: Browse Challenges
├── 👤 USER: Opens /challenges
├── 💻 SYSTEM: Loads predefined challenges list
├── 👁️ USER SEES: Challenge cards
└── ➡️ NEXT: Step 2

STEP 2: Join Challenge
├── 👤 USER: Clicks Join on a predefined challenge
├── 💻 SYSTEM: Checks 3-item active limit
├── 👁️ USER SEES: Join success (or limit error)
└── ➡️ NEXT: Step 3

STEP 3: Start Participation
├── 👤 USER: Opens challenge view
├── 💻 SYSTEM: Shows template phases/steps (read-only)
├── 👁️ USER SEES: Challenge progress UI
└── ➡️ NEXT: Flow ends
```

---

## Flow 5: Follow + Friend + View Friends-only Goal

**Goal:** User follows someone, becomes friends, and gains access to friends-only goals.

**Actors:** Regular users

**Entry Points:** `/people`

```
STEP 1: Find a Person
├── 👤 USER: Searches in People (/people)
├── 💻 SYSTEM: Returns user results
├── 👁️ USER SEES: User cards with Follow and Friend actions
└── ➡️ NEXT: Step 2

STEP 2: Follow
├── 👤 USER: Clicks Follow
├── 💻 SYSTEM: Creates follow relationship
├── 👁️ USER SEES: Follow state updated
└── ➡️ NEXT: Step 3

STEP 3: Send Friend Request
├── 👤 USER: Sends friend request
├── 💻 SYSTEM: Creates pending request
├── 👁️ USER SEES: Request pending status
└── ➡️ NEXT: Step 4

STEP 4: Accept Request
├── 👤 USER (Other): Accepts request
├── 💻 SYSTEM: Sets friendship to accepted
├── 👁️ USER SEES: Friendship confirmed
└── ➡️ NEXT: Step 5

STEP 5: View Friends-only Goal
├── 👤 USER: Opens friends-only goal
├── 💻 SYSTEM: Authorizes access
├── 👁️ USER SEES: Full goal detail
└── ➡️ NEXT: Flow ends
```

---

## Flow 6: Coach Creates Group Goal

**Goal:** Coach creates a group goal template and starts a group goal.

**Actors:** Coach

**Entry Points:** `/coach`

```
STEP 1: Create Template
├── 👤 USER: Opens Coach Center (/coach) and creates Group Goal Template
├── 💻 SYSTEM: Saves template draft
├── 👁️ USER SEES: Template editor
└── ➡️ NEXT: Step 2

STEP 2: Add Structure
├── 👤 USER: Adds phases and steps
├── 💻 SYSTEM: Validates structure
├── 👁️ USER SEES: Template structure preview
└── ➡️ NEXT: Step 3

STEP 3: Add Participants
├── 👤 USER: Searches and adds participants
├── 💻 SYSTEM: Validates users
├── 👁️ USER SEES: Participant list
└── ➡️ NEXT: Step 4

STEP 4: Start Group Goal
├── 👤 USER: Clicks Start
├── 💻 SYSTEM: Creates goal instances for participants (Active if under limit)
├── 👁️ USER SEES: Group goal dashboard
└── ➡️ NEXT: Flow ends
```

---

## Flow 7: Coach Tracks Progress

**Goal:** Coach reviews participant progress and identifies at-risk users.

**Actors:** Coach

**Entry Points:** `/coach/group-goals/:id`

```
STEP 1: Open Group Goal
├── 👤 USER: Visits /coach/group-goals/:id
├── 💻 SYSTEM: Loads participant progress data
├── 👁️ USER SEES: Participant table
└── ➡️ NEXT: Step 2

STEP 2: Filter At Risk
├── 👤 USER: Filters "at risk"
├── 💻 SYSTEM: Filters users with no recent activity
├── 👁️ USER SEES: Reduced list of at-risk participants
└── ➡️ NEXT: Step 3

STEP 3: Inspect Participant
├── 👤 USER: Clicks a participant
├── 💻 SYSTEM: Opens goal instance detail (coach view)
├── 👁️ USER SEES: Goal progress, updates, and activity
└── ➡️ NEXT: Flow ends
```

---

## Flow 8: Admin Creates Category + Predefined Challenge

**Goal:** Admin manages categories and publishes a predefined challenge.

**Actors:** Admin

**Entry Points:** `/admin/categories`, `/admin/challenges`

```
STEP 1: Create Category
├── 👤 USER: Opens /admin/categories and creates "Career"
├── 💻 SYSTEM: Saves category
├── 👁️ USER SEES: Category list updated
└── ➡️ NEXT: Step 2

STEP 2: Create Predefined Challenge
├── 👤 USER: Opens /admin/challenges and creates "30-Day Consistency"
├── 💻 SYSTEM: Opens challenge template editor
├── 👁️ USER SEES: Template form
└── ➡️ NEXT: Step 3

STEP 3: Add Phases and Steps
├── 👤 USER: Adds phases and steps
├── 💻 SYSTEM: Validates structure
├── 👁️ USER SEES: Template structure preview
└── ➡️ NEXT: Step 4

STEP 4: Publish Template
├── 👤 USER: Publishes/activates template
├── 💻 SYSTEM: Marks template active and visible in /challenges
├── 👁️ USER SEES: Confirmation and active status
└── ➡️ NEXT: Flow ends
```
