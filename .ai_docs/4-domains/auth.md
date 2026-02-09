# Authentication Patterns - Domain Documentation

## Overview

HeadsUp uses Phoenix's `phx.gen.auth` generated authentication system with database-backed session tokens and Bcrypt password hashing. Authentication is implemented through Plug middleware for controllers and `on_mount` hooks for LiveViews.

## Auth Files

| File | Purpose |
|------|---------|
| `/lib/heads_up/auth.ex` | Auth context - user lookup, registration, password management |
| `/lib/heads_up/users.ex` | User schema with password changesets |
| `/lib/heads_up/auth/user_token.ex` | Session token schema and functions |
| `/lib/heads_up/auth/user_notifier.ex` | Email notifications |
| `/lib/heads_up_web/user_auth.ex` | Plugs and LiveView hooks |
| `/lib/heads_up_web/controllers/user_session_controller.ex` | Login/logout controller |

## Auth Context Pattern

### User Lookup

```elixir
# File: /lib/heads_up/auth.ex
def get_user_by_email(email) when is_binary(email) do
  Repo.get_by(Users, email: email)
end

def get_user_by_email_and_password(email, password)
    when is_binary(email) and is_binary(password) do
  user = Repo.get_by(Users, email: email)
  if Users.valid_password?(user, password), do: user
end

def get_user!(id), do: Repo.get!(Users, id)
```

### User Registration

```elixir
# File: /lib/heads_up/auth.ex
def register_user(attrs) do
  %Users{}
  |> Users.registration_changeset(attrs)
  |> Repo.insert()
end

def change_user_registration(%Users{} = user, attrs \\ %{}) do
  Users.registration_changeset(user, attrs, hash_password: false, validate_email: false)
end
```

### Password Management

```elixir
# File: /lib/heads_up/auth.ex
def change_user_password(user, attrs \\ %{}) do
  Users.password_changeset(user, attrs, hash_password: false)
end

def update_user_password(user, password, attrs) do
  changeset =
    user
    |> Users.password_changeset(attrs)
    |> Users.validate_current_password(password)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:user, changeset)
  |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{user: user}} -> {:ok, user}
    {:error, :user, changeset, _} -> {:error, changeset}
  end
end

def reset_user_password(user, attrs) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:user, Users.password_changeset(user, attrs))
  |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{user: user}} -> {:ok, user}
    {:error, :user, changeset, _} -> {:error, changeset}
  end
end
```

### Session Token Management

```elixir
# File: /lib/heads_up/auth.ex
def generate_user_session_token(user) do
  {token, user_token} = UserToken.build_session_token(user)
  Repo.insert!(user_token)
  token
end

def get_user_by_session_token(token) do
  {:ok, query} = UserToken.verify_session_token_query(token)
  Repo.one(query)
end

def delete_user_session_token(token) do
  Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
  :ok
end
```

### Email Confirmation

```elixir
# File: /lib/heads_up/auth.ex
def deliver_user_confirmation_instructions(%Users{} = user, confirmation_url_fun)
    when is_function(confirmation_url_fun, 1) do
  if user.confirmed_at do
    {:error, :already_confirmed}
  else
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
  end
end

def confirm_user(token) do
  with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
       %Users{} = user <- Repo.one(query),
       {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
    {:ok, user}
  else
    _ -> :error
  end
end

defp confirm_user_multi(user) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:user, Users.confirm_changeset(user))
  |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
end
```

## UserAuth Plug Module

### Module Structure

```elixir
# File: /lib/heads_up_web/user_auth.ex
defmodule HeadsUpWeb.UserAuth do
  use HeadsUpWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias HeadsUp.Auth

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_heads_up_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  # ...
end
```

### Login Function

```elixir
# File: /lib/heads_up_web/user_auth.ex
def log_in_user(conn, user, params \\ %{}) do
  token = Auth.generate_user_session_token(user)
  user_return_to = get_session(conn, :user_return_to)

  conn
  |> renew_session()
  |> put_token_in_session(token)
  |> maybe_write_remember_me_cookie(token, params)
  |> redirect(to: user_return_to || signed_in_path(conn))
end

defp put_token_in_session(conn, token) do
  conn
  |> put_session(:user_token, token)
  |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
end

defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
  put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
end

defp maybe_write_remember_me_cookie(conn, _token, _params) do
  conn
end
```

### Logout Function

```elixir
# File: /lib/heads_up_web/user_auth.ex
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

### Fetch Current User Plug

```elixir
# File: /lib/heads_up_web/user_auth.ex
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

### Route Protection Plugs

```elixir
# File: /lib/heads_up_web/user_auth.ex
def redirect_if_user_is_authenticated(conn, _opts) do
  if conn.assigns[:current_user] do
    conn
    |> redirect(to: signed_in_path(conn))
    |> halt()
  else
    conn
  end
end

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
```

### API Authentication

```elixir
# File: /lib/heads_up_web/user_auth.ex
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

## LiveView on_mount Hooks

```elixir
# File: /lib/heads_up_web/user_auth.ex

# Mount current user without requiring authentication
def on_mount(:mount_current_user, _params, session, socket) do
  {:cont, mount_current_user(socket, session)}
end

# Require authenticated user, redirect if not
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

# Redirect if user is already authenticated
def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
  socket = mount_current_user(socket, session)

  if socket.assigns.current_user do
    {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
  else
    {:cont, socket}
  end
end

defp mount_current_user(socket, session) do
  Phoenix.Component.assign_new(socket, :current_user, fn ->
    if user_token = session["user_token"] do
      Auth.get_user_by_session_token(user_token)
    end
  end)
end
```

## Router Authentication Configuration

```elixir
# File: /lib/heads_up_web/router.ex
import HeadsUpWeb.UserAuth

pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {HeadsUpWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug :fetch_current_user   # <-- Auth plug
end

pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :fetch_current_user   # <-- Auth plug
end

pipeline :api_auth do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :require_authenticated_user_api  # <-- Require auth
end

# Public pages with optional auth
live_session :public,
  on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
  live "/goals", GoalLive.Index
  live "/goals/:id", GoalLive.Show
end

# Authenticated pages
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :authenticated,
    on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
    live "/goals/:id/edit", GoalLive.Edit
    live "/my-goals", MyGoalsLive.Index
  end
end

# Admin pages
scope "/admin", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :admin,
    on_mount: [
      {HeadsUpWeb.UserAuth, :ensure_authenticated},
      {HeadsUpWeb.AdminAuth, :ensure_admin}
    ] do
    live "/categories", Admin.GroupsLive.Index
  end
end

# Login pages (redirect if authenticated)
scope "/", HeadsUpWeb do
  pipe_through [:browser, :redirect_if_user_is_authenticated]

  live_session :redirect_if_user_is_authenticated,
    on_mount: [{HeadsUpWeb.UserAuth, :redirect_if_user_is_authenticated}] do
    live "/users/register", UserRegistrationLive, :new
    live "/users/log_in", UserLoginLive, :new
  end
end
```

## Password Hashing Pattern

```elixir
# File: /lib/heads_up/users.ex
defp maybe_hash_password(changeset, opts) do
  hash_password? = Keyword.get(opts, :hash_password, true)
  password = get_change(changeset, :password)

  if hash_password? && password && changeset.valid? do
    changeset
    |> validate_length(:password, max: 72, count: :bytes)
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  else
    changeset
  end
end

def valid_password?(%HeadsUp.Users{hashed_password: hashed_password}, password)
    when is_binary(hashed_password) and byte_size(password) > 0 do
  Bcrypt.verify_pass(password, hashed_password)
end

def valid_password?(_, _) do
  Bcrypt.no_user_verify()
  false
end

def validate_current_password(changeset, password) do
  changeset = cast(changeset, %{current_password: password}, [:current_password])

  if valid_password?(changeset.data, password) do
    changeset
  else
    add_error(changeset, :current_password, "is not valid")
  end
end
```

## Test Helpers

```elixir
# File: /test/support/conn_case.ex
def register_and_log_in_user(%{conn: conn}) do
  user = HeadsUp.AuthFixtures.user_fixture()
  %{conn: log_in_user(conn, user), user: user}
end

def log_in_user(conn, user) do
  token = HeadsUp.Auth.generate_user_session_token(user)

  conn
  |> Phoenix.ConnTest.init_test_session(%{})
  |> Plug.Conn.put_session(:user_token, token)
end
```

## Architectural Constraints

1. **Session Tokens**: Use database-backed session tokens, not stateless JWT
2. **Bcrypt Hashing**: Password hashing via Bcrypt
3. **Plug-Based Auth**: Authentication via Plug middleware for controllers
4. **on_mount Hooks**: LiveView auth via `on_mount` callbacks in router
5. **Separate API Auth**: API routes use `require_authenticated_user_api` for JSON responses
6. **Role Checking**: Admin checks via user.role field
7. **Ownership Pattern**: Resource access checks owner's user_id
