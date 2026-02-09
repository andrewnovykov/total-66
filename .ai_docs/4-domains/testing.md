# Testing Patterns - Domain Documentation

## Overview

HeadsUp uses ExUnit for testing with separate test case modules for different testing scenarios. Tests run in Ecto SQL sandbox mode for database isolation, and fixtures are used for test data creation.

## Test Support Files

| File | Purpose |
|------|---------|
| `/test/test_helper.exs` | Test configuration |
| `/test/support/conn_case.ex` | Controller test setup |
| `/test/support/data_case.ex` | Context test setup |
| `/test/support/fixtures/auth_fixtures.ex` | User fixture functions |
| `/test/support/fixtures/goals_fixtures.ex` | Goal fixture functions |
| `/test/support/fixtures/groups_fixtures.ex` | Group fixture functions |

## Test Case Modules

### DataCase - Context Tests

```elixir
# File: /test/support/data_case.ex
defmodule HeadsUp.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias HeadsUp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import HeadsUp.DataCase
    end
  end

  setup tags do
    HeadsUp.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HeadsUp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
```

### ConnCase - Controller Tests

```elixir
# File: /test/support/conn_case.ex
defmodule HeadsUpWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint HeadsUpWeb.Endpoint

      use HeadsUpWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import HeadsUpWeb.ConnCase
    end
  end

  setup tags do
    HeadsUp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = HeadsUp.AuthFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.
  """
  def log_in_user(conn, user) do
    token = HeadsUp.Auth.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
```

## Fixture Modules

### Auth Fixtures

```elixir
# File: /test/support/fixtures/auth_fixtures.ex
defmodule HeadsUp.AuthFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.Auth` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      user_name: "testuser#{unique_id}",
      name: "Test User #{unique_id}"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HeadsUp.Auth.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
```

## Test Structure Pattern

### Context Tests

```elixir
# File: /test/heads_up/goal_ownership_test.exs
defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goal, GoalStep}
  import HeadsUp.AuthFixtures

  describe "goal ownership validation" do
    setup do
      owner = user_fixture()
      other_user = user_fixture()

      {:ok, group} = HeadsUp.Groups.create_group(%{
        name: "Test Group",
        description: "Test",
        status: "published",
        image_path: "/images/test.png"
      })

      {:ok, goal} = Goals.create_goal(%{
        title: "Test Goal",
        description: "Test goal",
        status: :active,
        user_id: owner.id,
        group_id: group.id
      })

      %{goal: goal, owner: owner, other_user: other_user, group: group}
    end

    test "goal owner can update goal", %{goal: goal, owner: owner} do
      assert {:ok, updated_goal} = Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, owner.id)
      assert updated_goal.title == "Updated Title"
    end

    test "non-owner cannot update goal", %{goal: goal, other_user: other_user} do
      assert {:error, :unauthorized} = Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, other_user.id)
    end

    test "goal owner can create goal steps", %{goal: goal, owner: owner} do
      attrs = %{
        title: "Test Step",
        goal_id: goal.id,
        order: 1
      }

      assert {:ok, step} = Goals.create_goal_step_with_ownership(attrs, owner.id)
      assert step.title == "Test Step"
    end

    test "non-owner cannot create goal steps", %{goal: goal, other_user: other_user} do
      attrs = %{
        title: "Test Step",
        goal_id: goal.id,
        order: 1
      }

      assert {:error, :unauthorized} = Goals.create_goal_step_with_ownership(attrs, other_user.id)
    end
  end
end
```

### Describe Block Pattern

```elixir
describe "goal step ownership through goal" do
  test "properly loads goal association for ownership check" do
    owner = user_fixture()
    other_user = user_fixture()

    {:ok, group} = HeadsUp.Groups.create_group(%{...})
    {:ok, goal} = Goals.create_goal(%{...})
    {:ok, step} = Goals.create_goal_step(%{...})

    # Test that the step properly loads the goal for ownership validation
    fresh_step = Goals.get_goal_step!(step.id)

    # Owner can update
    assert {:ok, _} = Goals.update_goal_step_with_ownership(fresh_step, %{title: "Updated"}, owner.id)

    # Non-owner cannot update
    assert {:error, :unauthorized} = Goals.update_goal_step_with_ownership(fresh_step, %{title: "Updated"}, other_user.id)
  end
end
```

## Setup Patterns

### Setup with Context

```elixir
setup do
  owner = user_fixture()
  other_user = user_fixture()

  {:ok, group} = HeadsUp.Groups.create_group(%{
    name: "Test Group",
    description: "Test",
    status: "published",
    image_path: "/images/test.png"
  })

  {:ok, goal} = Goals.create_goal(%{
    title: "Test Goal",
    description: "Test goal",
    status: :active,
    user_id: owner.id,
    group_id: group.id
  })

  %{goal: goal, owner: owner, other_user: other_user, group: group}
end
```

### Setup with Pattern Matching

```elixir
setup %{conn: conn} do
  user = user_fixture()
  conn = log_in_user(conn, user)
  %{conn: conn, user: user}
end
```

### Named Setup

```elixir
setup :register_and_log_in_user

# The register_and_log_in_user function defined in ConnCase
def register_and_log_in_user(%{conn: conn}) do
  user = HeadsUp.AuthFixtures.user_fixture()
  %{conn: log_in_user(conn, user), user: user}
end
```

## Assertion Patterns

### Pattern Matching Assertions

```elixir
# Success tuple
assert {:ok, updated_goal} = Goals.update_goal_with_ownership(goal, attrs, owner.id)
assert updated_goal.title == "Updated Title"

# Error tuple
assert {:error, :unauthorized} = Goals.update_goal_with_ownership(goal, attrs, other_user.id)

# Changeset errors
assert {:error, %Ecto.Changeset{} = changeset} = Goals.create_goal(%{})
assert "can't be blank" in errors_on(changeset).title
```

### Errors On Helper

```elixir
# File: /test/support/data_case.ex
def errors_on(changeset) do
  Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end)
end

# Usage in tests
assert {:error, changeset} = Accounts.create_user(%{password: "short"})
assert "password is too short" in errors_on(changeset).password
assert %{password: ["password is too short"]} = errors_on(changeset)
```

## Async Tests

```elixir
# Async tests for tests that don't share database resources
defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true
  # ...
end

# Non-async for tests that may conflict
defmodule HeadsUp.SomeSharedResourceTest do
  use HeadsUp.DataCase, async: false
  # ...
end
```

## Controller Test Pattern

```elixir
defmodule HeadsUpWeb.PageControllerTest do
  use HeadsUpWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome"
  end
end
```

## LiveView Test Pattern

```elixir
defmodule HeadsUpWeb.GoalLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  setup :register_and_log_in_user

  test "displays user goals", %{conn: conn, user: user} do
    {:ok, view, html} = live(conn, ~p"/goals")
    assert html =~ "My Goals"
  end

  test "creates new goal", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, ~p"/goals")

    view
    |> element("button", "Create Goal")
    |> render_click()

    # ... form interaction
  end
end
```

## Test Organization

### Directory Structure

```
test/
├── test_helper.exs
├── support/
│   ├── conn_case.ex
│   ├── data_case.ex
│   └── fixtures/
│       ├── auth_fixtures.ex
│       ├── goals_fixtures.ex
│       └── groups_fixtures.ex
├── heads_up/
│   ├── auth_test.exs
│   ├── goal_deletion_test.exs
│   ├── goal_failure_test.exs
│   ├── goal_freeze_test.exs
│   ├── goal_ownership_test.exs
│   ├── goal_status_test.exs
│   ├── post_ownership_test.exs
│   └── activity_service_test.exs
└── heads_up_web/
    ├── controllers/
    │   ├── api/
    │   │   ├── category_api_test.exs
    │   │   ├── goal_api_test.exs
    │   │   ├── goal_controller_test.exs
    │   │   └── user_api_test.exs
    │   ├── page_controller_test.exs
    │   └── user_session_controller_test.exs
    ├── live/
    │   ├── goal_live/
    │   │   └── show_ui_consistency_test.exs
    │   ├── commitment_chart_enhanced_test.exs
    │   ├── commitment_chart_privacy_test.exs
    │   ├── connections_live_test.exs
    │   ├── goal_creation_integration_test.exs
    │   ├── goal_post_likes_and_image_test.exs
    │   ├── goal_privacy_test.exs
    │   └── users_live_show_social_test.exs
    ├── components/
    │   └── commitment_chart_test.exs
    └── user_auth_test.exs
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/heads_up/goal_ownership_test.exs

# Run tests with coverage
mix test --cover

# Run tests matching tag
mix test --only integration

# Run tests in watch mode (requires mix_test_watch)
mix test.watch
```

## Architectural Constraints

1. **Fixture Functions**: Use fixture modules for test data creation
2. **ConnCase**: Controller tests use ConnCase for connection setup
3. **DataCase**: Context tests use DataCase for database setup
4. **Describe Blocks**: Group related tests with describe blocks
5. **Sandbox Mode**: Tests run in Ecto SQL sandbox mode
6. **Isolated Tests**: Each test is independent, no shared state
7. **Async Where Possible**: Use `async: true` when tests don't share resources
