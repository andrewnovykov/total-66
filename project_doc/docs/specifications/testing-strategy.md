# Testing Strategy

## Test Pyramid

```
        /   E2E   \          ~10% of tests (Endorphin AI)
       / --------- \
      / Integration \        ~25% of tests (LiveView, API)
     / ------------- \
    /      Unit       \      ~65% of tests (Contexts, Schemas)
   / _________________ \
```

## Coverage Targets

| Layer       | Target                 | Measured By                     |
| ----------- | ---------------------- | ------------------------------- |
| Unit        | 80%                    | Statement coverage              |
| Integration | 70%                    | Branch coverage                 |
| E2E         | Critical paths covered | Scenario count                  |
| **Overall** | 75%                    | Combined via `mix test --cover` |

## Testing Frameworks

| Type        | Framework                                | Runner      |
| ----------- | ---------------------------------------- | ----------- |
| Unit        | ExUnit + DataCase                        | `mix test`  |
| Integration | ExUnit + ConnCase + Phoenix.LiveViewTest | `mix test`  |
| API         | ExUnit + ConnCase                        | `mix test`  |
| E2E (AI)    | Endorphin AI                             | `endorphin` |
| LiveView    | Phoenix.LiveViewTest                     | `mix test`  |
| Component   | ExUnit + Floki                           | `mix test`  |

---

## Test Directory Structure

```
test/
├── test_helper.exs                    # Test configuration
├── support/
│   ├── conn_case.ex                   # HTTP/controller test case
│   ├── data_case.ex                   # Context/database test case
│   └── fixtures/
│       ├── auth_fixtures.ex           # User fixture functions
│       ├── goals_fixtures.ex          # Goal/post fixture functions
│       └── groups_fixtures.ex         # Group/category fixture functions
├── heads_up/                          # Unit tests (contexts)
│   ├── auth_test.exs
│   ├── goal_ownership_test.exs
│   ├── goal_deletion_test.exs
│   ├── goal_failure_test.exs
│   ├── goal_freeze_test.exs
│   ├── goal_status_test.exs
│   ├── goal_subscription_test.exs
│   ├── post_ownership_test.exs
│   └── activity_service_test.exs
├── heads_up_web/                      # Integration tests
│   ├── controllers/
│   │   ├── page_controller_test.exs
│   │   ├── user_session_controller_test.exs
│   │   ├── error_html_test.exs
│   │   ├── error_json_test.exs
│   │   └── api/
│   │       ├── goal_api_test.exs
│   │       ├── goal_controller_test.exs
│   │       ├── user_api_test.exs
│   │       ├── category_api_test.exs
│   │       └── activity_controller_test.exs
│   ├── live/                          # LiveView integration tests
│   │   ├── goal_live/
│   │   │   └── show_ui_consistency_test.exs
│   │   ├── connections_live_test.exs
│   │   ├── feed_live_test.exs
│   │   ├── goal_privacy_test.exs
│   │   ├── goal_creation_integration_test.exs
│   │   ├── goal_post_likes_and_image_test.exs
│   │   ├── commitment_chart_enhanced_test.exs
│   │   ├── commitment_chart_privacy_test.exs
│   │   ├── users_live_show_social_test.exs
│   │   ├── user_login_live_test.exs
│   │   ├── user_registration_live_test.exs
│   │   ├── user_settings_live_test.exs
│   │   ├── user_forgot_password_live_test.exs
│   │   ├── user_reset_password_live_test.exs
│   │   ├── user_confirmation_live_test.exs
│   │   └── user_confirmation_instructions_live_test.exs
│   ├── components/
│   │   └── commitment_chart_test.exs
│   └── user_auth_test.exs             # Auth plug tests
└── endorphin/                         # E2E AI tests (Endorphin AI)
    └── .gitkeep                       # Placeholder for AI-driven tests
```

---

## Test Data Management

### Strategy:

- [x] Factories (programmatic data generation via fixture modules)
- [ ] Fixtures (static JSON/YAML files)
- [ ] Hybrid (factories + fixtures)

### Database Handling:

- [x] Transaction rollback per test (Ecto SQL Sandbox)
- [ ] Truncate tables between tests
- [x] Separate test database (`heads_up_test`)
- [ ] In-memory database

### Test Case Modules

#### DataCase - Context/Unit Tests

```elixir
defmodule HeadsUp.DataCase do
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

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HeadsUp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
```

#### ConnCase - Controller/LiveView Tests

```elixir
defmodule HeadsUpWeb.ConnCase do
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
end
```

### Fixture Pattern

```elixir
# test/support/fixtures/auth_fixtures.ex
defmodule HeadsUp.AuthFixtures do
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
end
```

```elixir
# test/support/fixtures/goals_fixtures.ex
defmodule HeadsUp.GoalsFixtures do
  def goal_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> ensure_user_id()
      |> ensure_group_id()

    {:ok, goal} =
      attrs
      |> valid_goal_attributes()
      |> HeadsUp.Goals.create_goal()
    goal
  end

  defp ensure_user_id(attrs) do
    if Map.has_key?(attrs, :user_id), do: attrs,
    else: Map.put(attrs, :user_id, HeadsUp.AuthFixtures.user_fixture().id)
  end
end
```

---

## E2E Testing with Endorphin AI

### Overview

E2E tests are powered by **Endorphin AI** (https://github.com/endorphin-ai/endorphin-ai), an AI-driven testing framework that uses natural language to describe test scenarios.

### Setup

```bash
# Install Endorphin AI
mix archive.install hex endorphin_ai

# Initialize in project
mix endorphin.init
```

### Test Location

E2E tests are stored in `test/endorphin/` directory.

### E2E Critical Flow Scenarios

| #   | Scenario                     | Steps                                                                            | Expected Result                        |
| --- | ---------------------------- | -------------------------------------------------------------------------------- | -------------------------------------- |
| 1   | User registration            | Navigate to /users/register, fill form (email, password, username, name), submit | Redirected to home, user logged in     |
| 2   | User login                   | Navigate to /users/log_in, enter credentials, submit                             | Redirected to home                     |
| 3   | Create goal                  | Login, navigate to /goals/new, fill title, select category, submit               | Goal created, redirected to goal       |
| 4   | Add goal steps               | View goal, add step title, click add                                             | Step appears in list                   |
| 5   | Complete goal step           | View goal, click step checkbox                                                   | Step marked complete, progress updates |
| 6   | Like a goal                  | View another user's goal, click like button                                      | Like count increases                   |
| 7   | Subscribe to goal            | View public goal, click subscribe                                                | Subscribed, appears in feed            |
| 8   | Create goal post             | View own goal, write post content, submit                                        | Post appears in goal feed              |
| 9   | Follow user                  | View user profile, click follow                                                  | Following count increases              |
| 10  | Send friend request          | View user profile, click add friend                                              | Request sent, pending status           |
| 11  | Accept friend request        | View connections, click accept on pending request                                | Friendship established                 |
| 12  | Update profile               | Navigate to /users/settings, update bio, save                                    | Profile updated                        |
| 13  | Change password              | Navigate to settings, enter current/new password, save                           | Password changed                       |
| 14  | Freeze goal (owner)          | View own goal, click freeze                                                      | Goal frozen, edit disabled             |
| 15  | Fail goal with reason        | View own goal, click fail, enter reason                                          | Goal marked failed with reason         |
| 16  | Privacy: private goal access | Create private goal, logout, try to access as guest                              | Access denied / redirect               |
| 17  | Privacy: friends-only goal   | Create friends-only goal, access as non-friend                                   | Access denied                          |
| 18  | Admin: manage categories     | Login as admin, navigate to /admin/categories, create category                   | Category created                       |

### Sample Endorphin AI Test

```yaml
# test/endorphin/user_registration.yaml
name: User Registration Flow
description: Test complete user registration process

steps:
    - navigate: /users/register
    - fill:
          email: test@example.com
          password: securepassword123
          user_name: testuser
          name: Test User
    - click: Register
    - assert:
          url: /
          text: Welcome

tags:
    - critical
    - auth
```

---

## CI Test Pipeline

### What Runs When:

| Trigger          | Tests Run                             | Timeout |
| ---------------- | ------------------------------------- | ------- |
| Every push       | Unit + `mix format --check-formatted` | 5 min   |
| Pull request     | Unit + Integration + Credo            | 15 min  |
| Merge to main    | Unit + Integration + E2E (Endorphin)  | 25 min  |
| Nightly schedule | Full suite + Coverage report          | 30 min  |

### Pipeline Stages:

```yaml
# .github/workflows/test.yml
name: Test

on:
    push:
        branches: [main, develop]
    pull_request:
        branches: [main]

jobs:
    test:
        runs-on: ubuntu-latest

        services:
            postgres:
                image: postgres:16
                env:
                    POSTGRES_USER: postgres
                    POSTGRES_PASSWORD: postgres
                    POSTGRES_DB: heads_up_test
                ports:
                    - 5432:5432
                options: >-
                    --health-cmd pg_isready
                    --health-interval 10s
                    --health-timeout 5s
                    --health-retries 5

        steps:
            - uses: actions/checkout@v4

            - name: Set up Elixir
              uses: erlef/setup-beam@v1
              with:
                  elixir-version: '1.14'
                  otp-version: '26'

            - name: Restore dependencies cache
              uses: actions/cache@v3
              with:
                  path: deps
                  key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}

            - name: Install dependencies
              run: mix deps.get

            - name: Check formatting
              run: mix format --check-formatted

            - name: Run Credo
              run: mix credo --strict

            - name: Setup database
              run: mix ecto.create && mix ecto.migrate
              env:
                  MIX_ENV: test

            - name: Run unit tests
              run: mix test test/heads_up/
              env:
                  MIX_ENV: test

            - name: Run integration tests
              run: mix test test/heads_up_web/
              env:
                  MIX_ENV: test

            - name: Run all tests with coverage
              run: mix test --cover
              env:
                  MIX_ENV: test

    e2e:
        runs-on: ubuntu-latest
        needs: test
        if: github.ref == 'refs/heads/main'

        steps:
            - uses: actions/checkout@v4

            - name: Run Endorphin AI E2E tests
              run: mix endorphin.run test/endorphin/
              env:
                  MIX_ENV: test
                  ENDORPHIN_API_KEY: ${{ secrets.ENDORPHIN_API_KEY }}
```

---

## Test Commands

```bash
# Run all tests
mix test

# Run specific test file
mix test test/heads_up/goal_ownership_test.exs

# Run specific test by line number
mix test test/heads_up/goal_ownership_test.exs:42

# Run tests matching tag
mix test --only integration

# Exclude tests with tag
mix test --exclude slow

# Run tests with coverage
mix test --cover

# Run tests in watch mode (requires mix_test_watch)
mix test.watch

# Run async tests only
mix test --only async

# Run with seed for reproducibility
mix test --seed 12345

# Run Endorphin AI E2E tests
mix endorphin.run test/endorphin/
```

---

## Test Tagging

```elixir
# Tag individual tests
@tag :slow
test "expensive operation" do
  # ...
end

@tag :integration
test "full flow" do
  # ...
end

@tag :capture_log
test "logs error" do
  # ...
end

# Tag entire module
@moduletag :integration
defmodule HeadsUpWeb.GoalCreationIntegrationTest do
  # All tests tagged as integration
end
```

---

## Assertion Patterns

### Success Tuple Pattern

```elixir
test "creates goal", %{user: user, group: group} do
  assert {:ok, goal} = Goals.create_goal(%{
    title: "My Goal",
    user_id: user.id,
    group_id: group.id
  })
  assert goal.title == "My Goal"
end
```

### Error Tuple Pattern

```elixir
test "rejects unauthorized update", %{goal: goal, other_user: other_user} do
  assert {:error, :unauthorized} = Goals.update_goal_with_ownership(
    goal,
    %{title: "New Title"},
    other_user.id
  )
end
```

### Changeset Error Pattern

```elixir
test "validates required fields" do
  assert {:error, changeset} = Goals.create_goal(%{})
  assert "can't be blank" in errors_on(changeset).title
end
```

### HTTP Response Pattern

```elixir
test "returns 200 for valid request", %{conn: conn} do
  conn = get(conn, ~p"/api/goals")
  assert json_response(conn, 200)
end

test "returns 401 for unauthenticated", %{conn: conn} do
  conn = get(conn, ~p"/api/goals/my")
  assert json_response(conn, 401)["error"]["message"] == "Authentication required"
end
```

### LiveView Pattern

```elixir
test "renders page", %{conn: conn} do
  {:ok, view, html} = live(conn, ~p"/goals")
  assert html =~ "Goals"
end

test "handles click event", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/goals")
  assert view
         |> element("button", "Create")
         |> render_click() =~ "New Goal"
end
```

---

## Performance Baselines

| Metric             | Target       | Tool                 |
| ------------------ | ------------ | -------------------- |
| Test suite runtime | < 60 seconds | `mix test`           |
| Individual test    | < 500ms      | ExUnit               |
| LiveView mount     | < 100ms      | Phoenix.LiveViewTest |
| API response (p95) | < 200ms      | Custom benchmarks    |

---

## Accessibility Testing

| Standard | Level  | Tool                         |
| -------- | ------ | ---------------------------- |
| WCAG     | 2.1 AA | Manual review + Endorphin AI |

**Key Pages to Test:**

- Home page (`/`)
- Login/Registration (`/users/log_in`, `/users/register`)
- Goals listing (`/goals`)
- Goal detail (`/goals/:id`)
- User profile (`/people/:username`)
- Settings (`/users/settings`)

---

## Test Naming Conventions

| Test Type  | Naming Pattern                 | Example                             |
| ---------- | ------------------------------ | ----------------------------------- |
| Permission | `"[role] can/cannot [action]"` | `"goal owner can update goal"`      |
| State      | `"properly [verb] [noun]"`     | `"properly loads goal association"` |
| HTTP       | `"[VERB] [path] [behavior]"`   | `"POST /api/goals creates goal"`    |
| Validation | `"validates [constraint]"`     | `"validates required title"`        |
| Edge case  | `"handles [scenario]"`         | `"handles missing user gracefully"` |

---

## Running Tests in Development

```bash
# Quick feedback loop
mix test --stale

# Watch mode
mix test.watch

# Focus on specific area
mix test test/heads_up/goals* --trace

# Debug failing test
iex -S mix test test/heads_up/goal_test.exs:42 --trace
```
