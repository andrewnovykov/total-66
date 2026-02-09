# Helpers Style Guide

This style guide documents the patterns and conventions used in HeadsUp helper modules.

## File Organization

```
lib/heads_up_web/helpers/
  avatar_helper.ex        # User avatar handling
  subscription_helper.ex  # Subscription/limit logic

lib/heads_up/auth/
  user_notifier.ex        # Email notification helper
```

## Module Structure

### Web Helper Module

```elixir
defmodule HeadsUpWeb.Helpers.AvatarHelper do
  @moduledoc """
  Helper functions for user avatars
  """

  @doc """
  Gets the appropriate avatar URL for a user, with fallback to default avatar
  """
  def get_user_avatar(user) do
    # Implementation
  end

  @doc """
  Generates a default avatar URL using ui-avatars.com service
  """
  def get_default_avatar(name \\ "User") do
    # Implementation
  end
end
```

**Pattern**:
- Namespace under `HeadsUpWeb.Helpers`
- Add moduledoc describing purpose
- Add @doc for each public function
- Provide default parameter values

### Context Helper Module

```elixir
defmodule HeadsUp.Auth.UserNotifier do
  import Swoosh.Email

  alias HeadsUp.Mailer

  # Private delivery function
  defp deliver(recipient, subject, body) do
    # Implementation
  end

  # Public notification functions
  def deliver_confirmation_instructions(user, url) do
    # Implementation
  end
end
```

**Pattern**: Place auth-related helpers under `HeadsUp.Auth` namespace.

## Avatar Helper Patterns

### Get User Avatar with Fallback

```elixir
def get_user_avatar(user) do
  case user.image_path do
    nil ->
      get_default_avatar(user.name || user.user_name || "User")

    path when is_binary(path) ->
      # Check if the image path exists (for uploaded files)
      if String.starts_with?(path, "/uploads/") do
        file_path = Path.join("priv/static", path)
        if File.exists?(file_path) do
          path
        else
          get_default_avatar(user.name || user.user_name || "User")
        end
      else
        # For other paths, use default avatar
        get_default_avatar(user.name || user.user_name || "User")
      end

    _ ->
      get_default_avatar(user.name || user.user_name || "User")
  end
end
```

**Pattern**:
- Use `case` with guard clauses for type checking
- Check file existence for uploaded files
- Cascading nil-safe fallback: `name || user_name || "User"`

### Generate Default Avatar URL

```elixir
def get_default_avatar(name \\ "User") do
  "https://ui-avatars.com/api/?name=#{URI.encode(name)}&background=6366f1&color=ffffff&size=128&bold=true"
end
```

**Pattern**:
- Use external avatar service for consistent defaults
- URL encode user input with `URI.encode/1`
- Provide default parameter value

## Subscription Helper Patterns

### Get Limit Based on Subscription

```elixir
def get_goal_limit(user) do
  case user.subscription_type do
    "free" -> 1
    "pro_3" -> 3
    "pro_5" -> 5
    "unlimited" -> :unlimited
    _ -> 1  # Default to free tier
  end
end
```

**Pattern**:
- Use atoms for special values (`:unlimited`)
- Always include catch-all clause with sensible default

### Check Permission with Limit

```elixir
def can_create_goal?(user, current_goal_count) do
  limit = get_goal_limit(user)

  case limit do
    :unlimited -> true
    limit when is_integer(limit) -> current_goal_count < limit
  end
end
```

**Pattern**:
- Accept count as parameter (caller provides current state)
- Use guard clause `when is_integer(limit)` for type safety
- Return boolean for permission checks

### Get Display Name

```elixir
def get_subscription_display_name(subscription_type) do
  case subscription_type do
    "free" -> "Free (1 goal)"
    "pro_3" -> "Pro (3 goals)"
    "pro_5" -> "Pro+ (5 goals)"
    "unlimited" -> "Premium (Unlimited goals)"
    _ -> "Free (1 goal)"
  end
end
```

**Pattern**: Separate function for display/UI purposes.

## Email Notifier Patterns

### Private Delivery Function

```elixir
defp deliver(recipient, subject, body) do
  email =
    new()
    |> to(recipient)
    |> from({"HeadsUp", "contact@example.com"})
    |> subject(subject)
    |> text_body(body)

  with {:ok, _metadata} <- Mailer.deliver(email) do
    {:ok, email}
  end
end
```

**Pattern**:
- Use Swoosh's pipe-friendly API
- Return `{:ok, email}` for consistency
- Use `with` for clean error propagation

### Notification Functions

```elixir
@doc """
Deliver instructions to confirm account.
"""
def deliver_confirmation_instructions(user, url) do
  deliver(user.email, "Confirmation instructions", """

  ==============================

  Hi #{user.email},

  You can confirm your account by visiting the URL below:

  #{url}

  If you didn't create an account with us, please ignore this.

  ==============================
  """)
end

@doc """
Deliver instructions to reset a user password.
"""
def deliver_reset_password_instructions(user, url) do
  deliver(user.email, "Reset password instructions", """

  ==============================

  Hi #{user.email},

  You can reset your password by visiting the URL below:

  #{url}

  If you didn't request this change, please ignore this.

  ==============================
  """)
end

@doc """
Deliver instructions to update a user email.
"""
def deliver_update_email_instructions(user, url) do
  deliver(user.email, "Update email instructions", """

  ==============================

  Hi #{user.email},

  You can change your email by visiting the URL below:

  #{url}

  If you didn't request this change, please ignore this.

  ==============================
  """)
end
```

**Pattern**:
- Function name: `deliver_{action}_instructions`
- Use heredoc `"""..."""` for multi-line email body
- Include interpolated values with `#{}`
- Add security notice ("If you didn't request...")

## Helper Usage

### In Templates

```heex
<div style={"background-image: url(\"#{HeadsUpWeb.Helpers.AvatarHelper.get_user_avatar(@current_user)}\");"}>
</div>

<% can_create = HeadsUpWeb.Helpers.SubscriptionHelper.can_create_goal?(@current_user, user_goal_count) %>
```

### In LiveViews

```elixir
import HeadsUpWeb.Helpers.AvatarHelper
import HeadsUpWeb.Helpers.SubscriptionHelper

# Then use directly
avatar_url = get_user_avatar(user)
can_create = can_create_goal?(user, count)
```

### In Controllers

```elixir
alias HeadsUpWeb.Helpers.SubscriptionHelper

if SubscriptionHelper.can_create_goal?(user, count) do
  # Allow creation
end
```

## Naming Conventions

| Function Type | Naming Pattern | Example |
|---------------|----------------|---------|
| Getter | `get_{resource}` | `get_user_avatar/1` |
| Default | `get_default_{resource}` | `get_default_avatar/1` |
| Permission | `can_{action}?` | `can_create_goal?/2` |
| Display | `get_{resource}_display_name` | `get_subscription_display_name/1` |
| Delivery | `deliver_{action}_instructions` | `deliver_confirmation_instructions/2` |

## Testing Helpers

```elixir
defmodule HeadsUpWeb.Helpers.AvatarHelperTest do
  use ExUnit.Case, async: true

  alias HeadsUpWeb.Helpers.AvatarHelper

  describe "get_user_avatar/1" do
    test "returns uploaded path when file exists" do
      user = %{image_path: "/uploads/avatar.png", name: "Test"}
      # Mock file existence check
      # ...
    end

    test "returns default avatar when path is nil" do
      user = %{image_path: nil, name: "Test User", user_name: "testuser"}
      assert AvatarHelper.get_user_avatar(user) =~ "ui-avatars.com"
      assert AvatarHelper.get_user_avatar(user) =~ "Test%20User"
    end
  end
end
```

**Pattern**: Test both success and fallback paths.
