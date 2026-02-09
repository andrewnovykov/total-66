# BUG-9: Logout is broken at /users/log_out

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## References
- User Story: [US-003](../USER-STORY/US-003-user-logout.md)
- Test Case: [TC-010](../Test-Case/TC-010-logout-success.md)
- Test Case: [TC-011](../Test-Case/TC-011-logout-session-invalidation.md)

## Priority
High

---

## Summary
Clicking "Log out" in the sidebar or mobile drawer does not work. The user stays logged in.

## Steps to Reproduce
1. Log in as any user
2. Click "Log out" in the sidebar (desktop) or drawer menu (mobile)
3. Observe that logout fails

## Expected Result
User is logged out, session is cleared, and user is redirected to the home page.

## Actual Result
Logout does not execute. The user remains logged in. The browser sends a GET request to `/users/log_out` which doesn't match the route (DELETE only).

---

## Investigation

### Related Files
- `lib/heads_up_web/components/layouts/app.html.heex` - Sidebar and drawer logout links
- `lib/heads_up_web/controllers/user_session_controller.ex` - DELETE handler
- `lib/heads_up_web/user_auth.ex` - `log_out_user/1`
- `lib/heads_up_web/router.ex` - Route definition

### Root Cause Analysis
Both logout links (sidebar at line 103 and drawer at line 267) used raw `<a>` tags with `data-method="delete"`. This pattern relies on `phoenix_html.js` to intercept the click and convert it to a DELETE form submission. However, in LiveView pages, LiveView's own navigation handler intercepts the click first, treating it as a regular GET navigation to `/users/log_out`. Since the route is defined as `delete "/users/log_out"`, the GET request doesn't match and fails.

### Fix Applied
Replaced both raw `<a>` tags with Phoenix's `<.link>` component using `method="delete"`:
```html
<.link href="/users/log_out" method="delete" class="...">
```

The `<.link>` component with `method="delete"` generates a proper inline `<form>` element with CSRF token that submits via POST with `_method=delete`, which works correctly in LiveView contexts.

## Resolution
- **Fixed Date:** 2026-02-06
- **Tests Added:** 1 regression test
- **Files Modified:**
  - `lib/heads_up_web/components/layouts/app.html.heex` (2 logout links fixed)
