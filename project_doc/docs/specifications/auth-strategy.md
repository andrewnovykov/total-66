# Authentication & Authorization Strategy

## Auth Method

- [ ] JWT (stateless tokens)
- [x] Server-side sessions (cookie-based)
- [ ] OAuth2 only (delegated auth)
- [ ] Hybrid

HeadsUp uses Phoenix's built-in session-based authentication with server-side token storage. Sessions are stored in the database via `users_tokens` table for persistence and easy invalidation.

---

## Session Configuration

| Setting         | Value                                |
| --------------- | ------------------------------------ |
| Store           | Database (`users_tokens` table)      |
| Cookie name     | `_heads_up_web_user_remember_me`     |
| Session key     | `:user_token` (in Phoenix session)   |
| Cookie flags    | `httpOnly`, `signed`, `sameSite=Lax` |
| Session expiry  | 60 days (remember me)                |
| Sliding window  | No (fixed expiry from creation)      |
| CSRF protection | Yes (Phoenix built-in)               |

### Session Token Storage

```elixir
# users_tokens table
schema "users_tokens" do
  field :token, :binary      # Hashed token
  field :context, :string    # "session", "confirm", "reset_password", "change:email"
  field :sent_to, :string    # Email for email-based tokens
  belongs_to :user, User
  timestamps(updated_at: false)
end
```

### Token Contexts

| Context          | Purpose                   | Expiry  |
| ---------------- | ------------------------- | ------- |
| `session`        | Login session             | 60 days |
| `confirm`        | Email confirmation        | 1 day   |
| `reset_password` | Password reset            | 1 day   |
| `change:*`       | Email change confirmation | 1 day   |

---

## Password Policy

| Rule                 | Value                        |
| -------------------- | ---------------------------- |
| Minimum length       | 12 characters                |
| Maximum length       | 72 characters (bcrypt limit) |
| Require uppercase    | No                           |
| Require number       | No                           |
| Require special char | No                           |
| Hashing algorithm    | Bcrypt                       |
| Salt rounds / cost   | 12 (default)                 |

### Password Validation

```elixir
# From HeadsUp.Users
def validate_password(changeset, opts) do
  changeset
  |> validate_required([:password])
  |> validate_length(:password, min: 12, max: 72)
  |> maybe_hash_password(opts)
end
```

### Test Environment

In test environment, bcrypt rounds are reduced to 1 for faster test execution:

```elixir
# config/test.exs
config :bcrypt_elixir, :log_rounds, 1
```

---

## MFA Configuration

| Setting        | Value           |
| -------------- | --------------- |
| MFA method     | Not implemented |
| Required for   | N/A             |
| Recovery codes | N/A             |

**Future consideration:** TOTP-based MFA for admin accounts.

---

## Role-Based Access Control (RBAC)

### Roles

```yaml
roles:
    admin:
        description: Full system access
        permissions:
            - users:read
            - users:write
            - users:delete
            - goals:read
            - goals:write:any
            - goals:delete:any
            - categories:read
            - categories:write
            - categories:delete
            - settings:manage

    user:
        description: Standard authenticated user
        permissions:
            - goals:read:public
            - goals:read:own
            - goals:write:own
            - goals:delete:own
            - posts:read:public
            - posts:write:own
            - posts:delete:own
            - profile:read:own
            - profile:write:own
            - users:follow
            - users:friend-request
```

### User Schema Role Field

```elixir
# HeadsUp.Users schema
field :role, :string, default: "user"

# Validation
|> validate_inclusion(:role, ["user", "admin"])
```

### Default role on registration: `user`

---

## Privacy Settings

HeadsUp supports user-level and goal-level privacy settings.

### User Privacy

| Setting        | Behavior                                       |
| -------------- | ---------------------------------------------- |
| `public`       | Profile visible to everyone, anyone can follow |
| `private`      | Profile visible only to friends                |
| `friends_only` | Profile visible, but only friends can follow   |

### Goal Privacy

| Setting   | Behavior                                  |
| --------- | ----------------------------------------- |
| `public`  | Visible to everyone, anyone can subscribe |
| `private` | Visible only to owner                     |
| `friends` | Visible only to owner and friends         |

---

## Protected Route Middleware

### Route Protection Levels

| Level                               | Behavior                                           |
| ----------------------------------- | -------------------------------------------------- |
| `public`                            | Accessible to everyone                             |
| `mount_current_user`                | Loads user if logged in, continues either way      |
| `redirect_if_user_is_authenticated` | Guest-only pages (login, register)                 |
| `ensure_authenticated`              | Requires login — redirect to `/users/log_in`       |
| `ensure_admin`                      | Requires admin role — redirect to `/` if not       |
| `require_authenticated_user`        | Plug version of ensure_authenticated               |
| `require_authenticated_user_api`    | API version — returns 401 JSON instead of redirect |

### LiveView On-Mount Hooks

```elixir
# HeadsUpWeb.UserAuth
def on_mount(:mount_current_user, _params, session, socket)
def on_mount(:ensure_authenticated, _params, session, socket)
def on_mount(:redirect_if_user_is_authenticated, _params, session, socket)

# HeadsUpWeb.AdminAuth
def on_mount(:ensure_admin, _params, _session, socket)
```

### Router Pipeline Usage

```elixir
# Public pages
live_session :public,
  on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
  live "/goals", GoalLive.Index
end

# Guest-only pages (login, register)
live_session :redirect_if_user_is_authenticated,
  on_mount: [{HeadsUpWeb.UserAuth, :redirect_if_user_is_authenticated}] do
  live "/users/log_in", UserLoginLive, :new
end

# Authenticated pages
live_session :authenticated,
  on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
  live "/my-goals", MyGoalsLive.Index
end

# Admin pages
live_session :admin,
  on_mount: [
    {HeadsUpWeb.UserAuth, :ensure_authenticated},
    {HeadsUpWeb.AdminAuth, :ensure_admin}
  ] do
  live "/admin/categories", Admin.GroupsLive.Index
end
```

### API Pipeline

```elixir
# Public API
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :fetch_current_user
end

# Authenticated API
pipeline :api_auth do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :require_authenticated_user_api
end
```

---

## Auth Endpoints

### Web Routes (LiveView)

| Endpoint                               | Method | Auth       | Description          |
| -------------------------------------- | ------ | ---------- | -------------------- |
| `/users/register`                      | GET    | guest-only | Registration form    |
| `/users/log_in`                        | GET    | guest-only | Login form           |
| `/users/log_in`                        | POST   | guest-only | Submit login         |
| `/users/log_out`                       | DELETE | auth       | End session          |
| `/users/reset_password`                | GET    | guest-only | Forgot password form |
| `/users/reset_password/:token`         | GET    | guest-only | Reset password form  |
| `/users/confirm`                       | GET    | guest-only | Resend confirmation  |
| `/users/confirm/:token`                | GET    | public     | Confirm email        |
| `/users/settings`                      | GET    | auth       | User settings        |
| `/users/settings/confirm_email/:token` | GET    | auth       | Confirm email change |

### Session Controller

```elixir
# HeadsUpWeb.UserSessionController
def create(conn, %{"user" => user_params})
def delete(conn, _params)
```

---

## Authentication Flow

### Registration Flow

```
1. User visits /users/register
2. Fills form with email, password, username, name
3. POST creates user with hashed password
4. Optional: Confirmation email sent
5. User can log in immediately (email confirmation optional)
```

### Login Flow

```
1. User visits /users/log_in
2. Enters email and password
3. POST validates credentials via Bcrypt
4. Session token generated and stored in database
5. Token set in session + optional remember_me cookie
6. LiveSocket ID set for real-time disconnect on logout
7. Redirect to return_to URL or home
```

### Logout Flow

```
1. User clicks logout (DELETE /users/log_out)
2. Session token deleted from database
3. LiveView socket broadcast: disconnect
4. Session cleared
5. Remember me cookie deleted
6. Redirect to home
```

### Password Reset Flow

```
1. User visits /users/reset_password
2. Enters email address
3. Reset token generated and stored in database
4. Email sent with reset link (expires in 1 day)
5. User clicks link, visits /users/reset_password/:token
6. Token validated against database
7. User enters new password
8. Password updated, all tokens invalidated
9. User must log in again
```

---

## Security Measures

### Session Security

| Measure          | Implementation                         |
| ---------------- | -------------------------------------- |
| Session fixation | Session ID renewed on login/logout     |
| CSRF protection  | Phoenix built-in (form tokens)         |
| Secure cookies   | `secure: true` in production           |
| HttpOnly cookies | Yes (prevents XSS access)              |
| SameSite         | `Lax` (prevents CSRF from other sites) |
| Token hashing    | SHA-256 before database storage        |

### Password Security

| Measure            | Implementation                            |
| ------------------ | ----------------------------------------- |
| Timing attacks     | `Bcrypt.no_user_verify()` on invalid user |
| Password storage   | Bcrypt hash only (no plaintext)           |
| Password in logs   | `:redact` option prevents logging         |
| Password in memory | Virtual field cleared after hashing       |

### API Security

| Measure                  | Implementation           |
| ------------------------ | ------------------------ |
| Unauthenticated requests | 401 JSON response        |
| Unauthorized requests    | 403 JSON response        |
| Rate limiting            | Not implemented (future) |

---

## Ownership Verification

Resource ownership is checked at the controller/context level:

```elixir
# Example: Goal ownership check
def authorize_owner(conn, goal) do
  if goal.user_id == conn.assigns.current_user.id do
    conn
  else
    conn
    |> put_status(:forbidden)
    |> json(%{error: "You can only modify your own goals"})
    |> halt()
  end
end

# Self-interaction prevention
def can_like_goal?(user, goal) do
  user.id != goal.user_id
end

def can_subscribe_to_goal?(user, goal) do
  user.id != goal.user_id &&
    (goal.privacy == "public" ||
     (goal.privacy == "friends" && are_friends?(user, goal.user)))
end
```

---

## Future Enhancements

### OAuth2 Providers (Planned)

| Provider | Status  | Scopes             |
| -------- | ------- | ------------------ |
| Google   | Planned | `email`, `profile` |
| GitHub   | Planned | `user:email`       |

### MFA (Planned)

- TOTP-based authentication for admin accounts
- Recovery codes for account recovery
- Optional for regular users

### API Authentication (Planned)

- JWT tokens for mobile app
- API keys for third-party integrations

---

## Related Files

| File                                                      | Purpose                       |
| --------------------------------------------------------- | ----------------------------- |
| `lib/heads_up/auth.ex`                                    | Auth context (business logic) |
| `lib/heads_up/auth/user_token.ex`                         | Token schema and queries      |
| `lib/heads_up/auth/user_notifier.ex`                      | Email notifications           |
| `lib/heads_up/users.ex`                                   | User schema and changesets    |
| `lib/heads_up_web/user_auth.ex`                           | Plugs and LiveView hooks      |
| `lib/heads_up_web/admin_auth.ex`                          | Admin authorization           |
| `lib/heads_up_web/controllers/user_session_controller.ex` | Session controller            |
| `lib/heads_up_web/live/user_*_live.ex`                    | Auth LiveViews                |
