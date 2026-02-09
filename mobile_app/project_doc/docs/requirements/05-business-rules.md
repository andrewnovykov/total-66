# Business Rules

## Authentication & Access

### How Do Users Log In?

- [x] Email and password
- [ ] Social login (Google, Facebook, etc.) — future feature
- [ ] Magic link — not planned
- [ ] Phone number + code — not planned

### Who Can Register?

- [x] Anyone can create an account
- Registration requires: username/nickname (unique), email (unique), password, password confirmation
- Optional at registration: profile photo, short bio

### What Happens After Registration?

- [x] Immediate access — user is logged in right away after registering
- [ ] Email verification — not needed for MVP
- [ ] Admin approval — not needed

### Password Requirements

- Minimum length: decided by framework best practices
- Secure hashing (bcrypt or equivalent)

### Roles & Access

- Roles: user / coach / admin
- Roles are assigned by admin (or user is promoted)
- Visitors cannot access My Goals, Coach Center, or Admin pages
- Navigation/menu options are role-based

---

## Core Rules

### Max 3 Active Items

- A user can have at most 3 active items at the same time
- Active items count includes:
  - Active goals
  - Active challenges
  - Active group goal instances

### Visibility Enforcement

- Public: everyone
- Friends-only: accepted friends only
- Private: owner only
- Coach exception: coach can view progress for their group goal participants

### Challenge Rules

- Predefined challenge templates are read-only for participants
- User-created challenge tasks are editable by the creator

### Interaction Rules

- Like/dislike is a toggle per target (cannot like and dislike the same item at once)
- Guests cannot like, comment, follow, or send friend requests

### Social Graph Rules

- Follow is one-way (follow/unfollow)
- Friends are mutual with request + accept workflow
