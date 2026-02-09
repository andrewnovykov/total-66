# Test Support Style Guide

This style guide documents the patterns and conventions used in HeadsUp test support files.

## File Organization

```
test/
  test_helper.exs          # Test configuration
  support/
    data_case.ex           # Database test case
    conn_case.ex           # HTTP/connection test case
    fixtures/
      auth_fixtures.ex     # User/auth fixtures
      goals_fixtures.ex    # Goal fixtures
      groups_fixtures.ex   # Group fixtures
```

## Test Helper

```elixir
# test/test_helper.exs
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(HeadsUp.Repo, :manual)
```

**Pattern**: Enable sandbox mode for database isolation.

## Case Templates

### DataCase (Database Tests)

```elixir
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

**Pattern**:
- Use `ExUnit.CaseTemplate` for reusable test setup
- `using` block imports common modules
- `setup_sandbox` enables database isolation
- `errors_on/1` helper for changeset error testing

### ConnCase (HTTP Tests)

```elixir
defmodule HeadsUpWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint HeadsUpWeb.Endpoint

      use HeadsUpWeb, :verified_routes

      # Import conveniences for testing with connections
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

**Pattern**:
- Inherit from DataCase for database setup
- Provide `build_conn()` in setup
- `register_and_log_in_user/1` for authenticated tests
- `log_in_user/2` for custom user authentication

## Fixtures Modules

### Auth Fixtures

```elixir
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

**Pattern**:
- Use `System.unique_integer()` for unique values
- `valid_*_attributes/1` for building params
- `*_fixture/1` for creating database records
- Allow attribute overrides with `Enum.into(attrs, defaults)`

### Goals Fixtures (Example)

```elixir
defmodule HeadsUp.GoalsFixtures do
  @moduledoc """
  Test helpers for creating goal entities.
  """

  import HeadsUp.AuthFixtures
  import HeadsUp.GroupsFixtures

  def valid_goal_attributes(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()
    group = attrs[:group] || group_fixture()

    Enum.into(attrs, %{
      title: "Test Goal #{System.unique_integer([:positive])}",
      description: "A test goal description",
      status: :active,
      privacy: :public,
      user_id: user.id,
      group_id: group.id
    })
  end

  def goal_fixture(attrs \\ %{}) do
    {:ok, goal} =
      attrs
      |> valid_goal_attributes()
      |> HeadsUp.Goals.create_goal()

    goal
  end

  def goal_with_steps_fixture(attrs \\ %{}, step_count \\ 3) do
    goal = goal_fixture(attrs)

    steps =
      for i <- 1..step_count do
        {:ok, step} = HeadsUp.Goals.create_goal_step(%{
          title: "Step #{i}",
          goal_id: goal.id,
          order: i
        })
        step
      end

    {goal, steps}
  end
end
```

**Pattern**:
- Import dependent fixtures
- Auto-create dependencies if not provided
- Provide composite fixtures (`goal_with_steps_fixture`)

### Groups Fixtures (Example)

```elixir
defmodule HeadsUp.GroupsFixtures do
  @moduledoc """
  Test helpers for creating group entities.
  """

  def valid_group_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Group #{System.unique_integer([:positive])}",
      description: "A test group",
      status: "published",
      image_path: "/images/default.png"
    })
  end

  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> valid_group_attributes()
      |> HeadsUp.Groups.create_group()

    group
  end
end
```

## Using Test Support

### In Tests

```elixir
defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.Goals
  import HeadsUp.AuthFixtures

  setup do
    owner = user_fixture()
    other_user = user_fixture()

    {:ok, group} = HeadsUp.Groups.create_group(%{
      name: "Test Group",
      description: "Test",
      status: "published",
      image_path: "/images/test.png"
    })

    %{owner: owner, other_user: other_user, group: group}
  end

  test "owner can update", %{owner: owner, group: group} do
    {:ok, goal} = Goals.create_goal(%{
      title: "Test",
      user_id: owner.id,
      group_id: group.id
    })

    assert {:ok, _} = Goals.update_goal_with_ownership(goal, %{title: "Updated"}, owner.id)
  end
end
```

### With Authentication

```elixir
defmodule HeadsUpWeb.Api.GoalControllerTest do
  use HeadsUpWeb.ConnCase

  import HeadsUp.AuthFixtures
  import HeadsUp.GroupsFixtures

  # Use setup callback for authenticated tests
  setup :register_and_log_in_user

  test "creates goal", %{conn: conn, user: user} do
    group = group_fixture()

    conn = post(conn, ~p"/api/goals", %{
      goal: %{title: "New Goal", group_id: group.id}
    })

    assert json_response(conn, 201)
  end
end
```

### Error Assertions

```elixir
test "returns validation errors", %{conn: conn} do
  conn = post(conn, ~p"/api/goals", %{goal: %{}})

  assert %{"title" => ["can't be blank"]} = errors_on(conn.assigns.changeset)
end
```

## Naming Conventions

| File | Module | Purpose |
|------|--------|---------|
| `data_case.ex` | `HeadsUp.DataCase` | Database tests |
| `conn_case.ex` | `HeadsUpWeb.ConnCase` | HTTP tests |
| `auth_fixtures.ex` | `HeadsUp.AuthFixtures` | User fixtures |
| `goals_fixtures.ex` | `HeadsUp.GoalsFixtures` | Goal fixtures |
| `groups_fixtures.ex` | `HeadsUp.GroupsFixtures` | Group fixtures |

## Function Naming Patterns

| Function Type | Pattern | Example |
|---------------|---------|---------|
| Unique value | `unique_{field}` | `unique_user_email` |
| Valid attributes | `valid_{resource}_attributes` | `valid_user_attributes` |
| Valid constant | `valid_{field}` | `valid_user_password` |
| Fixture creator | `{resource}_fixture` | `user_fixture`, `goal_fixture` |
| Composite fixture | `{resource}_with_{relation}_fixture` | `goal_with_steps_fixture` |
| Helper | descriptive name | `extract_user_token`, `log_in_user` |

## Test Case Usage

```elixir
# For database-only tests (contexts, schemas)
use HeadsUp.DataCase, async: true

# For HTTP tests (controllers, API)
use HeadsUpWeb.ConnCase

# For LiveView tests
use HeadsUpWeb.ConnCase
import Phoenix.LiveViewTest
```

## Async Testing

```elixir
# Enable async for isolated tests
use HeadsUp.DataCase, async: true

# Disable async for tests that share state
use HeadsUp.DataCase, async: false
```

**Pattern**: Use `async: true` unless tests modify shared state.
