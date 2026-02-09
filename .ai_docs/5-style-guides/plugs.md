# Plugs Style Guide

This style guide documents the patterns and conventions used in HeadsUp Plug modules.

## File Organization

```
lib/heads_up_web/
  user_auth.ex       # User authentication plug
  admin_auth.ex      # Admin authorization plug
```

## Module Structure

### User Auth Module

```elixir
defmodule HeadsUpWeb.UserAuth do
  use HeadsUpWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias HeadsUp.Auth

  # Module attributes for configuration
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_heads_up_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  # ... plug functions
end
```

**Pattern**:
- Use `HeadsUpWeb, :verified_routes` for verified route helpers
- Import `Plug.Conn` and `Phoenix.Controller`
- Define configuration as module attributes
- Cookie names follow convention: `_app_name_cookie_purpose`

### Admin Auth Module

```elixir
defmodule HeadsUpWeb.AdminAuth do
  import Plug.Conn
  import Phoenix.Controller

  # ... plug functions
end
```

**Pattern**: Minimal imports, focused on authorization only.

## Authentication Plugs

### Log In User

```elixir
@doc """
Logs the user in.

It renews the session ID and clears the whole session
to avoid fixation attacks. See the renew_session
function to customize this behaviour.

It also sets a `:live_socket_id` key in the session,
so LiveView sessions are identified and automatically
disconnected on log out.
"""
def log_in_user(conn, user, params \\ %{}) do
  token = Auth.generate_user_session_token(user)
  user_return_to = get_session(conn, :user_return_to)

  conn
  |> renew_session()
  |> put_token_in_session(token)
  |> maybe_write_remember_me_cookie(token, params)
  |> redirect(to: user_return_to || signed_in_path(conn))
end
```

**Pattern**:
- Generate session token via Auth context
- Renew session to prevent fixation attacks
- Store return path for post-login redirect
- Support optional "remember me" functionality

### Remember Me Cookie

```elixir
defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
  put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
end

defp maybe_write_remember_me_cookie(conn, _token, _params) do
  conn
end
```

**Pattern**: Use function clause matching for optional behavior.

### Log Out User

```elixir
@doc """
Logs the user out.

It clears all session data for safety. See renew_session.
"""
def log_out_user(conn) do
  user_token = get_session(conn, :user_token)
  user_token && Auth.delete_user_session_token(user_token)

  if live_socket_id = get_session(conn, :live_socket_id) do
    HeadsUpWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
  end

  conn
  |> renew_session()
  |> delete_resp_cookie(@remember_me_cookie)
  |> redirect(to: ~p"/")
end
```

**Pattern**:
- Delete session token from database
- Broadcast disconnect to LiveView sockets
- Clear session and cookies
- Redirect to home

### Fetch Current User

```elixir
@doc """
Authenticates the user by looking into the session
and remember me token.
"""
def fetch_current_user(conn, _opts) do
  {user_token, conn} = ensure_user_token(conn)
  user = user_token && Auth.get_user_by_session_token(user_token)
  assign(conn, :current_user, user)
end

defp ensure_user_token(conn) do
  if token = get_session(conn, :user_token) do
    {token, conn}
  else
    conn = fetch_cookies(conn, signed: [@remember_me_cookie])

    if token = conn.cookies[@remember_me_cookie] do
      {token, put_token_in_session(conn, token)}
    else
      {nil, conn}
    end
  end
end
```

**Pattern**: Check session first, fall back to remember me cookie.

## Session Management

### Renew Session

```elixir
defp renew_session(conn) do
  delete_csrf_token()

  conn
  |> configure_session(renew: true)
  |> clear_session()
end
```

**Pattern**: Delete CSRF token, renew session ID, clear session data.

### Put Token in Session

```elixir
defp put_token_in_session(conn, token) do
  conn
  |> put_session(:user_token, token)
  |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
end
```

**Pattern**: Store both user token and LiveView socket ID.

## LiveView On Mount Callbacks

### Mount Current User

```elixir
def on_mount(:mount_current_user, _params, session, socket) do
  {:cont, mount_current_user(socket, session)}
end

defp mount_current_user(socket, session) do
  Phoenix.Component.assign_new(socket, :current_user, fn ->
    if user_token = session["user_token"] do
      Auth.get_user_by_session_token(user_token)
    end
  end)
end
```

**Pattern**:
- Use `assign_new` to avoid duplicate database queries
- Access session with string keys in LiveView
- Return `{:cont, socket}` to continue mounting

### Ensure Authenticated

```elixir
def on_mount(:ensure_authenticated, _params, session, socket) do
  socket = mount_current_user(socket, session)

  if socket.assigns.current_user do
    {:cont, socket}
  else
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
      |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

    {:halt, socket}
  end
end
```

**Pattern**:
- Mount user first, then check
- Use `{:halt, socket}` to stop mounting and redirect
- Add flash message before redirect

### Redirect If Authenticated

```elixir
def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
  socket = mount_current_user(socket, session)

  if socket.assigns.current_user do
    {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
  else
    {:cont, socket}
  end
end
```

**Pattern**: Redirect authenticated users away from login/register pages.

## Route Protection Plugs

### Require Authenticated User (HTML)

```elixir
@doc """
Used for routes that require the user to be authenticated.
"""
def require_authenticated_user(conn, _opts) do
  if conn.assigns[:current_user] do
    conn
  else
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> maybe_store_return_to()
    |> redirect(to: ~p"/users/log_in")
    |> halt()
  end
end

defp maybe_store_return_to(%{method: "GET"} = conn) do
  put_session(conn, :user_return_to, current_path(conn))
end

defp maybe_store_return_to(conn), do: conn
```

**Pattern**:
- Use bracket notation `[:current_user]` for nil-safe access
- Store return path only for GET requests
- Always call `halt()` after redirect

### Require Authenticated User (API)

```elixir
@doc """
Require authenticated user for API endpoints.
Returns JSON error instead of redirect.
"""
def require_authenticated_user_api(conn, _opts) do
  if conn.assigns[:current_user] do
    conn
  else
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{
      error: %{
        message: "Authentication required"
      },
      success: false
    })
    |> halt()
  end
end
```

**Pattern**: Return JSON response for API endpoints, not redirect.

### Redirect If Authenticated

```elixir
@doc """
Used for routes that require the user to not be authenticated.
"""
def redirect_if_user_is_authenticated(conn, _opts) do
  if conn.assigns[:current_user] do
    conn
    |> redirect(to: signed_in_path(conn))
    |> halt()
  else
    conn
  end
end
```

## Admin Authorization

### Require Admin (Plug)

```elixir
def require_admin_user(conn, _opts) do
  if conn.assigns[:current_user] && conn.assigns.current_user.role == "admin" do
    conn
  else
    conn
    |> put_flash(:error, "Access denied. Admin privileges required.")
    |> redirect(to: "/")
    |> halt()
  end
end
```

**Pattern**: Check both authentication and role.

### Ensure Admin (LiveView)

```elixir
def on_mount(:ensure_admin, _params, _session, socket) do
  if socket.assigns.current_user && socket.assigns.current_user.role == "admin" do
    {:cont, socket}
  else
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "Access denied. Admin privileges required.")
      |> Phoenix.LiveView.redirect(to: "/")

    {:halt, socket}
  end
end
```

**Pattern**: Admin check assumes authentication already verified by prior on_mount.

## Private Helper Functions

### Signed In Path

```elixir
defp signed_in_path(_conn), do: ~p"/"
```

**Pattern**: Centralize post-login redirect path.

## Usage in Router

### Pipeline Definition

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {HeadsUpWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug :fetch_current_user  # Custom plug
end

pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :fetch_current_user  # Also used for API
end
```

### Route Protection

```elixir
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Protected routes
end
```

### LiveView Session Protection

```elixir
live_session :authenticated,
  on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
  live "/my-goals", MyGoalsLive.Index
end

live_session :admin,
  on_mount: [
    {HeadsUpWeb.UserAuth, :ensure_authenticated},
    {HeadsUpWeb.AdminAuth, :ensure_admin}
  ] do
  live "/admin/categories", Admin.GroupsLive.Index
end
```

**Pattern**: Stack multiple on_mount callbacks for layered authorization.

## Documentation Style

```elixir
@doc """
Handles mounting and authenticating the current_user in LiveViews.

## `on_mount` arguments

  * `:mount_current_user` - Assigns current_user
    to socket assigns based on user_token, or nil if
    there's no user_token or no matching user.

  * `:ensure_authenticated` - Authenticates the user from the session,
    and assigns the current_user to socket assigns based
    on user_token.
    Redirects to login page if there's no logged user.

## Examples

Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
the current_user:

    defmodule HeadsUpWeb.PageLive do
      use HeadsUpWeb, :live_view

      on_mount {HeadsUpWeb.UserAuth, :mount_current_user}
      ...
    end
"""
```

**Pattern**: Document all on_mount variants with examples.
