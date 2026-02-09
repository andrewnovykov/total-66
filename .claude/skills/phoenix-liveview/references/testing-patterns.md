# Testing Patterns for Phoenix Applications

Comprehensive testing strategies for Phoenix, LiveView, and Ecto.

## Table of Contents

1. [Test Setup](#test-setup)
2. [Context Testing](#context-testing)
3. [LiveView Testing](#liveview-testing)
4. [Controller Testing](#controller-testing)
5. [Factory Patterns](#factory-patterns)
6. [Test Helpers](#test-helpers)

## Test Setup

### DataCase for Context Tests

```elixir
# test/support/data_case.ex
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.DataCase
      import MyApp.Factory
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
```

### ConnCase for Controller/LiveView Tests

```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint MyAppWeb.Endpoint
      use MyAppWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase
      import MyApp.Factory
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn}) do
    user = MyApp.Factory.insert(:user)
    %{conn: log_in_user(conn, user), user: user}
  end

  def log_in_user(conn, user) do
    token = MyApp.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
```

## Context Testing

### Basic CRUD Tests

```elixir
defmodule MyApp.BlogTest do
  use MyApp.DataCase
  alias MyApp.Blog
  alias MyApp.Blog.Post

  describe "list_posts/0" do
    test "returns all non-deleted posts" do
      post = insert(:post)
      deleted_post = insert(:post, deleted_at: DateTime.utc_now())

      result = Blog.list_posts()

      assert length(result) == 1
      assert hd(result).id == post.id
    end

    test "returns empty list when no posts" do
      assert Blog.list_posts() == []
    end
  end

  describe "get_post!/1" do
    test "returns the post with given id" do
      post = insert(:post)
      result = Blog.get_post!(post.id)
      assert result.id == post.id
    end

    test "raises when post not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Blog.get_post!(999)
      end
    end
  end

  describe "create_post/1" do
    test "with valid data creates a post" do
      user = insert(:user)
      attrs = %{title: "Test Post", body: "Test body", user_id: user.id}

      assert {:ok, %Post{} = post} = Blog.create_post(attrs)
      assert post.title == "Test Post"
      assert post.body == "Test body"
      assert post.user_id == user.id
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_post(%{})
    end

    test "with missing required fields returns error" do
      assert {:error, changeset} = Blog.create_post(%{title: "Only Title"})
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_post/2" do
    test "with valid data updates the post" do
      post = insert(:post)
      attrs = %{title: "Updated Title"}

      assert {:ok, updated_post} = Blog.update_post(post, attrs)
      assert updated_post.title == "Updated Title"
    end

    test "with invalid data returns error changeset" do
      post = insert(:post)

      assert {:error, %Ecto.Changeset{}} = Blog.update_post(post, %{title: ""})
    end
  end

  describe "update_post_with_ownership/3" do
    test "updates when user owns the post" do
      user = insert(:user)
      post = insert(:post, user: user)

      assert {:ok, _post} = Blog.update_post_with_ownership(
        post, %{title: "New Title"}, user.id
      )
    end

    test "returns error when user doesn't own the post" do
      post = insert(:post)
      other_user = insert(:user)

      assert {:error, :unauthorized} = Blog.update_post_with_ownership(
        post, %{title: "New Title"}, other_user.id
      )
    end

    test "returns error when post is frozen" do
      user = insert(:user)
      post = insert(:post, user: user, status: :frozen)

      assert {:error, :frozen} = Blog.update_post_with_ownership(
        post, %{title: "New Title"}, user.id
      )
    end
  end

  describe "like_post/2" do
    test "creates a like" do
      post = insert(:post)
      user = insert(:user)

      assert {:ok, _like} = Blog.like_post(post.id, user.id)
    end

    test "returns error when liking own post" do
      user = insert(:user)
      post = insert(:post, user: user)

      assert {:error, :cannot_like_own_post} = Blog.like_post(post.id, user.id)
    end

    test "returns error when already liked" do
      post = insert(:post)
      user = insert(:user)

      assert {:ok, _like} = Blog.like_post(post.id, user.id)
      assert {:error, _changeset} = Blog.like_post(post.id, user.id)
    end
  end
end
```

### Testing with Associations

```elixir
describe "list_posts_with_comments/0" do
  test "preloads comments" do
    post = insert(:post)
    comment = insert(:comment, post: post)

    [result] = Blog.list_posts_with_comments()

    assert result.id == post.id
    assert length(result.comments) == 1
    assert hd(result.comments).id == comment.id
  end
end
```

## LiveView Testing

### Basic LiveView Tests

```elixir
defmodule MyAppWeb.PostLive.IndexTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "Index" do
    test "lists all posts", %{conn: conn} do
      post = insert(:post)

      {:ok, _view, html} = live(conn, ~p"/posts")

      assert html =~ "Posts"
      assert html =~ post.title
    end

    test "shows empty state when no posts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      assert html =~ "No posts yet"
    end
  end

  describe "Index (authenticated)" do
    setup :register_and_log_in_user

    test "can create a post", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert view
             |> element("a", "New Post")
             |> render_click() =~ "New Post"

      assert_patch(view, ~p"/posts/new")

      assert view
             |> form("#post-form", post: %{title: "Test", body: "Content"})
             |> render_submit()

      assert_patch(view, ~p"/posts")

      html = render(view)
      assert html =~ "Post created"
      assert html =~ "Test"
    end

    test "can delete own post", %{conn: conn, user: user} do
      post = insert(:post, user: user)

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert view
             |> element("#post-#{post.id} button", "Delete")
             |> render_click()

      refute has_element?(view, "#post-#{post.id}")
    end

    test "cannot delete other user's post", %{conn: conn} do
      other_user = insert(:user)
      post = insert(:post, user: other_user)

      {:ok, view, _html} = live(conn, ~p"/posts")

      # Delete button should not be visible
      refute has_element?(view, "#post-#{post.id} button", "Delete")
    end
  end
end
```

### LiveView Form Testing

```elixir
describe "Form validation" do
  setup :register_and_log_in_user

  test "shows validation errors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/posts/new")

    assert view
           |> form("#post-form", post: %{title: ""})
           |> render_change() =~ "can&#39;t be blank"
  end

  test "clears errors when fixed", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/posts/new")

    view
    |> form("#post-form", post: %{title: ""})
    |> render_change()

    html =
      view
      |> form("#post-form", post: %{title: "Valid Title"})
      |> render_change()

    refute html =~ "can&#39;t be blank"
  end
end
```

### Testing Real-time Updates

```elixir
describe "Real-time updates" do
  test "receives new posts via PubSub", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/posts")

    # Simulate a new post being created
    post = insert(:post)
    Phoenix.PubSub.broadcast(MyApp.PubSub, "posts", {:post_created, post})

    # Wait for the update
    assert render(view) =~ post.title
  end

  test "updates post when edited", %{conn: conn} do
    post = insert(:post)
    {:ok, view, _html} = live(conn, ~p"/posts")

    updated_post = %{post | title: "Updated Title"}
    Phoenix.PubSub.broadcast(MyApp.PubSub, "posts", {:post_updated, updated_post})

    assert render(view) =~ "Updated Title"
  end
end
```

### LiveComponent Testing

```elixir
defmodule MyAppWeb.PostLive.FormComponentTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "FormComponent" do
    setup :register_and_log_in_user

    test "renders form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      assert has_element?(view, "#post-form")
      assert has_element?(view, "input[name='post[title]']")
      assert has_element?(view, "textarea[name='post[body]']")
    end

    test "submits form successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      view
      |> form("#post-form", post: %{title: "New Post", body: "Post content"})
      |> render_submit()

      assert_redirected(view, ~p"/posts")
    end
  end
end
```

## Controller Testing

### API Controller Tests

```elixir
defmodule MyAppWeb.API.PostControllerTest do
  use MyAppWeb.ConnCase
  alias MyApp.Blog

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all posts", %{conn: conn} do
      post = insert(:post)

      conn = get(conn, ~p"/api/posts")

      assert %{"data" => [%{"id" => id}]} = json_response(conn, 200)
      assert id == post.id
    end
  end

  describe "create" do
    setup :register_and_log_in_api_user

    test "creates post with valid data", %{conn: conn} do
      attrs = %{title: "Test", body: "Content"}

      conn = post(conn, ~p"/api/posts", post: attrs)

      assert %{"data" => %{"id" => id}} = json_response(conn, 201)
      assert Blog.get_post!(id)
    end

    test "returns errors with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/posts", post: %{})

      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors["title"]
    end
  end

  describe "update" do
    setup :register_and_log_in_api_user

    test "updates own post", %{conn: conn, user: user} do
      post = insert(:post, user: user)

      conn = put(conn, ~p"/api/posts/#{post}", post: %{title: "Updated"})

      assert %{"data" => %{"title" => "Updated"}} = json_response(conn, 200)
    end

    test "returns 403 for other user's post", %{conn: conn} do
      post = insert(:post)

      conn = put(conn, ~p"/api/posts/#{post}", post: %{title: "Updated"})

      assert json_response(conn, 403)
    end
  end

  defp register_and_log_in_api_user(%{conn: conn}) do
    user = insert(:user)
    token = MyApp.Accounts.generate_api_token(user)
    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    %{conn: conn, user: user}
  end
end
```

## Factory Patterns

```elixir
# test/support/factory.ex
defmodule MyApp.Factory do
  alias MyApp.Repo

  def build(:user) do
    %MyApp.Accounts.User{
      email: "user#{System.unique_integer([:positive])}@example.com",
      name: "Test User",
      hashed_password: Bcrypt.hash_pwd_salt("password123!")
    }
  end

  def build(:post) do
    %MyApp.Blog.Post{
      title: "Test Post #{System.unique_integer([:positive])}",
      body: "This is test content for the post.",
      status: :draft,
      user: build(:user)
    }
  end

  def build(:comment) do
    %MyApp.Blog.Comment{
      body: "This is a test comment.",
      post: build(:post),
      user: build(:user)
    }
  end

  def build(:post_like) do
    %MyApp.Blog.PostLike{
      post: build(:post),
      user: build(:user)
    }
  end

  # Build with custom attributes
  def build(factory_name, attrs) when is_list(attrs) do
    build(factory_name, Map.new(attrs))
  end

  def build(factory_name, attrs) when is_map(attrs) do
    factory_name
    |> build()
    |> struct!(attrs)
  end

  # Insert into database
  def insert(factory_name, attrs \\ %{}) do
    factory_name
    |> build(attrs)
    |> Repo.insert!()
  end

  # Insert with association
  def insert_with_user(factory_name, attrs \\ %{}) do
    user = insert(:user)
    insert(factory_name, Map.put(attrs, :user, user))
  end
end
```

## Test Helpers

### Error Helper

```elixir
# In DataCase
def errors_on(changeset) do
  Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end)
end
```

### Async Test Tags

```elixir
# For tests that can run in parallel
@tag :async
test "my parallel test" do
  # ...
end

# For tests that need database isolation
@tag :skip_sandbox
test "test that modifies global state" do
  # ...
end
```

### Custom Assertions

```elixir
# test/support/assertions.ex
defmodule MyApp.TestAssertions do
  import ExUnit.Assertions

  def assert_changeset_valid(changeset) do
    assert changeset.valid?, "Expected changeset to be valid, got: #{inspect(changeset.errors)}"
  end

  def assert_changeset_error(changeset, field, message) do
    refute changeset.valid?
    errors = MyApp.DataCase.errors_on(changeset)
    assert message in Map.get(errors, field, []),
      "Expected error '#{message}' on field #{field}, got: #{inspect(errors)}"
  end
end
```
