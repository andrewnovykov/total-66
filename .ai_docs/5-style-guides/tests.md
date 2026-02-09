# Tests Style Guide

This style guide documents the patterns and conventions used in HeadsUp test files.

## File Organization

```
test/
  heads_up/
    auth_test.exs                    # Context tests
    goal_ownership_test.exs          # Feature tests
    goal_deletion_test.exs
    goal_failure_test.exs
    goal_freeze_test.exs
    goal_status_test.exs
    post_ownership_test.exs
  heads_up_web/
    controllers/
      page_controller_test.exs       # Controller tests
      api/
        goal_api_test.exs            # API tests
        goal_controller_test.exs
        user_api_test.exs
        category_api_test.exs
    live/
      goal_privacy_test.exs          # LiveView tests
      connections_live_test.exs
      user_login_live_test.exs
      user_settings_live_test.exs
    user_auth_test.exs               # Plug tests
```

## Module Structure

### DataCase Test (Context/Business Logic)

```elixir
defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goal, GoalStep}
  import HeadsUp.AuthFixtures

  describe "goal ownership validation" do
    setup do
      # Setup code
    end

    test "test description", %{context: value} do
      # Test code
    end
  end
end
```

**Pattern**:
- Use `HeadsUp.DataCase` for database tests
- `async: true` for parallel execution
- Import fixtures modules
- Group related tests with `describe`

### ConnCase Test (Controllers/HTTP)

```elixir
defmodule HeadsUpWeb.PageControllerTest do
  use HeadsUpWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome"
  end
end
```

**Pattern**: Use `HeadsUpWeb.ConnCase` for HTTP tests.

### Authenticated Test

```elixir
defmodule HeadsUpWeb.Api.GoalControllerTest do
  use HeadsUpWeb.ConnCase

  setup :register_and_log_in_user

  describe "authenticated requests" do
    test "creates goal", %{conn: conn, user: user} do
      # Test with authenticated user
    end
  end
end
```

**Pattern**: Use `setup :register_and_log_in_user` for authenticated tests.

## Setup Patterns

### Basic Setup

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

**Pattern**:
- Create fixtures in setup
- Return map of test context
- Use meaningful variable names

### Setup with Tags

```elixir
@tag :capture_log
test "logs error when..." do
  # Test that logs
end
```

### Setup Callback

```elixir
setup :register_and_log_in_user

test "authenticated action", %{conn: conn, user: user} do
  # Test body
end
```

## Assertion Patterns

### Success Assertions

```elixir
test "goal owner can update goal", %{goal: goal, owner: owner} do
  assert {:ok, updated_goal} = Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, owner.id)
  assert updated_goal.title == "Updated Title"
end
```

**Pattern**: Pattern match on `{:ok, result}` and assert fields.

### Error Assertions

```elixir
test "non-owner cannot update goal", %{goal: goal, other_user: other_user} do
  assert {:error, :unauthorized} = Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, other_user.id)
end
```

**Pattern**: Assert specific error atom.

### Boolean Assertions

```elixir
test "goal owner can toggle step completion", %{goal: goal, owner: owner} do
  {:ok, step} = Goals.create_goal_step(%{...})

  assert {:ok, updated_step} = Goals.toggle_goal_step_completion_with_ownership(step, owner.id)
  assert updated_step.completed == true
end
```

### HTTP Response Assertions

```elixir
test "returns 200 for valid request", %{conn: conn} do
  conn = get(conn, ~p"/api/goals")
  assert json_response(conn, 200)
end

test "returns 401 for unauthenticated request", %{conn: conn} do
  conn = get(conn, ~p"/api/goals/my")
  assert json_response(conn, 401)["error"]["message"] == "Authentication required"
end

test "returns 403 for unauthorized action", %{conn: conn, goal: goal} do
  conn = put(conn, ~p"/api/goals/#{goal.id}", %{title: "New"})
  assert json_response(conn, 403)
end
```

### HTML Response Assertions

```elixir
test "renders home page", %{conn: conn} do
  conn = get(conn, ~p"/")
  assert html_response(conn, 200) =~ "Welcome"
end
```

## Describe Blocks

### Feature-Based Organization

```elixir
describe "goal ownership validation" do
  # All ownership-related tests
end

describe "goal step ownership through goal" do
  # Tests for nested resource ownership
end
```

### Action-Based Organization

```elixir
describe "create goal" do
  test "creates with valid params" do end
  test "fails with invalid params" do end
end

describe "update goal" do
  test "updates with valid params" do end
  test "fails without ownership" do end
end
```

## Test Naming Conventions

```elixir
# Permission tests
test "goal owner can update goal"
test "non-owner cannot update goal"
test "goal owner can create goal steps"
test "non-owner cannot create goal steps"

# State tests
test "properly loads goal association for ownership check"

# HTTP tests
test "GET / returns 200"
test "POST /api/goals creates goal"
test "DELETE /api/goals/:id requires authentication"
```

**Pattern**:
- "can/cannot" for permission tests
- "properly" for behavior verification
- HTTP verb + path for API tests

## Testing Ownership Patterns

### Direct Resource Ownership

```elixir
test "goal owner can update goal", %{goal: goal, owner: owner} do
  assert {:ok, updated_goal} = Goals.update_goal_with_ownership(goal, %{title: "Updated"}, owner.id)
  assert updated_goal.title == "Updated"
end

test "non-owner cannot update goal", %{goal: goal, other_user: other_user} do
  assert {:error, :unauthorized} = Goals.update_goal_with_ownership(goal, %{title: "Updated"}, other_user.id)
end
```

### Nested Resource Ownership

```elixir
test "goal owner can create goal steps", %{goal: goal, owner: owner} do
  attrs = %{title: "Test Step", goal_id: goal.id, order: 1}
  assert {:ok, step} = Goals.create_goal_step_with_ownership(attrs, owner.id)
  assert step.title == "Test Step"
end

test "non-owner cannot create goal steps", %{goal: goal, other_user: other_user} do
  attrs = %{title: "Test Step", goal_id: goal.id, order: 1}
  assert {:error, :unauthorized} = Goals.create_goal_step_with_ownership(attrs, other_user.id)
end
```

### Toggle Operations

```elixir
test "goal owner can toggle step completion", %{goal: goal, owner: owner} do
  {:ok, step} = Goals.create_goal_step(%{
    title: "Step to Toggle",
    goal_id: goal.id,
    order: 1,
    completed: false
  })

  assert {:ok, updated_step} = Goals.toggle_goal_step_completion_with_ownership(step, owner.id)
  assert updated_step.completed == true
end
```

### Association Loading

```elixir
test "properly loads goal association for ownership check" do
  owner = user_fixture()
  other_user = user_fixture()

  {:ok, group} = HeadsUp.Groups.create_group(%{...})
  {:ok, goal} = Goals.create_goal(%{user_id: owner.id, ...})
  {:ok, step} = Goals.create_goal_step(%{goal_id: goal.id, ...})

  # Test with fresh fetch (simulating real-world usage)
  fresh_step = Goals.get_goal_step!(step.id)

  assert {:ok, _} = Goals.update_goal_step_with_ownership(fresh_step, %{title: "Updated"}, owner.id)
  assert {:error, :unauthorized} = Goals.update_goal_step_with_ownership(fresh_step, %{title: "Updated"}, other_user.id)
end
```

## LiveView Testing

```elixir
defmodule HeadsUpWeb.Live.ConnectionsLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  setup :register_and_log_in_user

  test "renders connections page", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/connections")
    assert html =~ "Connections"
  end

  test "can switch tabs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/connections")

    assert view
           |> element("button", "Followers")
           |> render_click() =~ "Followers"
  end
end
```

## API Testing

```elixir
defmodule HeadsUpWeb.Api.GoalApiTest do
  use HeadsUpWeb.ConnCase

  import HeadsUp.AuthFixtures

  setup :register_and_log_in_user

  describe "POST /api/goals" do
    test "creates goal with valid params", %{conn: conn, user: user} do
      # Create required group
      {:ok, group} = HeadsUp.Groups.create_group(%{...})

      conn = post(conn, ~p"/api/goals", %{
        goal: %{
          title: "My Goal",
          group_id: group.id
        }
      })

      assert %{"data" => goal} = json_response(conn, 201)
      assert goal["title"] == "My Goal"
    end

    test "returns 422 with invalid params", %{conn: conn} do
      conn = post(conn, ~p"/api/goals", %{goal: %{}})
      assert json_response(conn, 422)["error"]
    end
  end
end
```

## Error Case Testing

```elixir
describe "error handling" do
  test "returns not_found for missing resource", %{conn: conn} do
    conn = get(conn, ~p"/api/goals/999999")
    assert json_response(conn, 404)["error"]["message"] == "Goal not found"
  end

  test "returns bad_request for invalid ID", %{conn: conn} do
    conn = get(conn, ~p"/api/goals/invalid")
    assert json_response(conn, 400)["error"]["message"] == "Invalid goal ID"
  end
end
```

## Test File Naming

| Test Type | File Pattern | Example |
|-----------|--------------|---------|
| Context | `{context}_test.exs` | `auth_test.exs` |
| Feature | `{feature}_test.exs` | `goal_ownership_test.exs` |
| Controller | `{controller}_test.exs` | `page_controller_test.exs` |
| API | `{resource}_api_test.exs` | `goal_api_test.exs` |
| LiveView | `{live_view}_test.exs` | `connections_live_test.exs` |
| Plug | `{plug}_test.exs` | `user_auth_test.exs` |
