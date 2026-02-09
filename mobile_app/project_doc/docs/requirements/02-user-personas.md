cat <<'EOF' > project_doc/docs/requirements/02-user-personas.md

# User Personas

## User Type 1: Guest (Visitor)

### Who They Are

- Description: Visitors exploring public content before signing up
- Technical ability: Medium
- Frequency of use: Occasionally

### Their Goals

- Discover goals, challenges, and users worth following
- Decide whether to register

### Their Frustrations

- Blocked from interacting without an account
- Limited visibility into friends-only or private content

### What They Can Do

| Action              | Create | Read | Update | Delete |
| ------------------- | ------ | ---- | ------ | ------ |
| Goals (public)      | ❌     | ✅   | ❌     | ❌     |
| Challenges (public) | ❌     | ✅   | ❌     | ❌     |
| Profiles (public)   | ❌     | ✅   | ❌     | ❌     |
| Goal Posts (public) | ❌     | ✅   | ❌     | ❌     |

### Pages They Access

- Home
- Goals
- Challenges
- Groups
- People
- Public goal pages
- Public profile pages

---

## User Type 2: Regular User (Goal Creator)

### Who They Are

- Description: Primary users who create goals, track progress, and engage socially
- Technical ability: Medium
- Frequency of use: Daily

### Their Goals

- Create and complete structured goals
- Stay accountable via challenges and social feedback

### Their Frustrations

- Limited to 3 active items
- Cannot edit predefined challenge templates

### What They Can Do

| Action                  | Create | Read | Update | Delete |
| ----------------------- | ------ | ---- | ------ | ------ |
| Goals (own)             | ✅     | ✅   | ✅     | ✅     |
| Challenges (custom)     | ✅     | ✅   | ✅     | ✅     |
| Challenges (predefined) | ❌     | ✅   | ❌     | ❌     |
| Goal Posts (own)        | ✅     | ✅   | ✅     | ✅     |
| Comments/Reactions      | ✅     | ✅   | ✅     | ✅     |
| Follows/Friends         | ✅     | ✅   | ✅     | ✅     |

### Pages They Access

- All public pages
- My Goals
- Goal detail
- Challenge detail
- Profile (self/others)

---

## User Type 3: Coach

### Who They Are

- Description: Power users who manage group goals and track participant progress
- Technical ability: Medium
- Frequency of use: Weekly

### Their Goals

- Run group goals with structured plans
- Monitor participant progress and activity

### Their Frustrations

- Cannot edit participant progress directly
- Still bound by the 3 active items rule

### What They Can Do

| Action                         | Create | Read | Update | Delete |
| ------------------------------ | ------ | ---- | ------ | ------ |
| Group Goal Templates           | ✅     | ✅   | ✅     | ✅     |
| Group Goal Enrollments         | ✅     | ✅   | ✅     | ✅     |
| Participant Goals (coach view) | ❌     | ✅   | ❌     | ❌     |

### Pages They Access

- Coach Center
- Group goal dashboards
- All regular user pages

---

## User Type 4: Admin

### Who They Are

- Description: System administrators who manage categories and predefined challenges
- Technical ability: High
- Frequency of use: As needed

### Their Goals

- Curate categories and challenge templates
- Keep the system organized and safe

### Their Frustrations

- Cannot modify user progress directly
- No access to private goals unless explicitly granted

### What They Can Do

| Action                | Create | Read | Update | Delete |
| --------------------- | ------ | ---- | ------ | ------ |
| Categories            | ✅     | ✅   | ✅     | ✅     |
| Predefined Challenges | ✅     | ✅   | ✅     | ✅     |
| Users (admin view)    | ❌     | ✅   | ❌     | ❌     |

### Pages They Access

- Admin categories
- Admin challenges
- All public pages
  EOF
