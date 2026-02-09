---
name: phoenix-liveview
description: "Phoenix Framework and LiveView development skill for building production-ready Elixir web applications. Use when working with Phoenix 1.7+, LiveView, Ecto schemas, contexts, migrations, controllers, or any Elixir/Phoenix development task. Triggers on requests involving (1) Creating or editing LiveViews, LiveComponents, or function components, (2) Writing Ecto schemas, changesets, or migrations, (3) Implementing Phoenix contexts with CRUD operations, (4) Building real-time features with PubSub, (5) API development with controllers and JSON views, (6) Authentication and authorization patterns, (7) Testing Phoenix applications."
---

# Phoenix LiveView Development

Production-ready patterns for Phoenix 1.7+, LiveView, and Ecto.

## Tech Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Elixir | ~> 1.14 | Core language |
| Phoenix | ~> 1.7 | Web framework |
| Phoenix LiveView | ~> 1.0 | Real-time UI |
| Ecto | ~> 3.12 | Database ORM |
| PostgreSQL | Latest | Database |
| Tailwind CSS | 3.4+ | Styling |

## Project Structure

```
lib/
├── my_app/                    # Business logic (contexts + schemas)
│   ├── accounts.ex            # Context - public API
│   ├── accounts/
│   │   └── user.ex            # Schema
│   ├── blog.ex                # Context
│   ├── blog/
│   │   ├── post.ex
│   │   └── comment.ex
│   └── repo.ex
├── my_app_web/                # Web interface
│   ├── live/
│   │   └── post_live/
│   │       ├── index.ex       # LiveView
│   │       ├── show.ex
│   │       └── form_component.ex
│   ├── components/
│   │   └── core_components.ex
│   ├── controllers/api/
│   ├── router.ex
│   └── endpoint.ex
priv/repo/migrations/
test/
```

## Schema Pattern

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :text
    field :status, Ecto.Enum, values: [:draft, :published], default: :draft
    field :deleted_at, :utc_datetime

    belongs_to :user, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
    has_many :likes, MyApp.Blog.PostLike
    has_many :likers, through: [:likes, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :status, :user_id])
    |> validate_required([:title, :body, :user_id])
    |> validate_length(:title, min: 3, max: 255)
    |> foreign_key_constraint(:user_id)
  end
end
```

**Conventions:**
- `Ecto.Enum` for status fields with defined values
- `timestamps(type: :utc_datetime)` always
- Soft delete with `deleted_at` field
- `@doc false` for changeset unless documented
- `has_many :through` for virtual associations

## Context Pattern

```elixir
defmodule MyApp.Blog do
  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.Blog.Post

  # List - exclude soft-deleted
  def list_posts do
    from(p in Post, where: is_nil(p.deleted_at))
    |> Repo.all()
    |> Repo.preload([:user])
  end

  # IMPORTANT: Batched counts to prevent N+1 queries
  # When displaying counts for a list, NEVER query per-item
  def counts_by_post_ids(post_ids) when is_list(post_ids) do
    from(c in Comment,
      where: c.post_id in ^post_ids,
      group_by: c.post_id,
      select: {c.post_id, count(c.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def get_post!(id) do
    Repo.get!(Post, id)
    |> Repo.preload([:user, :comments])
  end

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  # Ownership validation pattern
  def update_post_with_ownership(%Post{} = post, attrs, user_id) do
    cond do
      post.user_id != user_id -> {:error, :unauthorized}
      post.status == :archived -> {:error, :archived}
      true -> update_post(post, attrs)
    end
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_post(%Post{} = post) do
    post
    |> Post.changeset(%{deleted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  # Self-interaction prevention
  def like_post(post_id, user_id) do
    post = get_post!(post_id)
    if post.user_id == user_id do
      {:error, :cannot_like_own_post}
    else
      # insert like
    end
  end
end
```

**Function naming:**
- `list_*` - Multiple records
- `get_*!` - Single or raises
- `create_*`, `update_*`, `delete_*` - CRUD
- `*_with_ownership` - Validates ownership
- `change_*` - Returns changeset for forms

**Error tuples:**
```elixir
{:ok, resource}
{:error, :unauthorized}
{:error, :not_found}
{:error, :frozen}
{:error, :cannot_like_own_post}
{:error, %Ecto.Changeset{}}
```

## LiveView Pattern

```elixir
defmodule MyAppWeb.PostLive.Index do
  use MyAppWeb, :live_view
  alias MyApp.Blog

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "posts")
    end

    # CRITICAL: When adding counts/aggregates to lists, use batched queries
    # See references/best-practices.md for N+1 query prevention
    posts = Blog.list_posts()
    posts_with_counts = add_counts(posts)  # Use batched query, NOT per-item

    {:ok, assign(socket, :posts, posts_with_counts)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post!(id)
    current_user = socket.assigns.current_user

    case Blog.delete_post_with_ownership(post, current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Deleted")
         |> assign(:posts, Blog.list_posts())}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Not authorized")}
    end
  end

  def handle_info({:post_created, post}, socket) do
    {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4">
      <h1 class="text-2xl font-bold">Posts</h1>
      <div :for={post <- @posts} class="bg-white rounded-lg shadow p-4 mt-4">
        <h2 class="font-semibold"><%= post.title %></h2>
        <button phx-click="delete" phx-value-id={post.id}
          data-confirm="Are you sure?">
          Delete
        </button>
      </div>
    </div>
    """
  end
end
```

**Conventions:**
- `socket.assigns[:current_user]` - nil-safe access
- `socket.assigns.current_user` - guaranteed authenticated
- Subscribe to PubSub only when `connected?(socket)`
- `push_navigate` for redirects
- Embedded templates with `~H` sigil

## LiveComponent Pattern

```elixir
defmodule MyAppWeb.PostLive.FormComponent do
  use MyAppWeb, :live_component
  alias MyApp.Blog

  def render(assigns) do
    ~H"""
    <div>
      <.header><%= @title %></.header>
      <.simple_form for={@form} id="post-form" phx-target={@myself}
        phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} label="Title" />
        <.input field={@form[:body]} type="textarea" label="Body" />
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(%{post: post} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(Blog.change_post(post)))}
  end

  def handle_event("validate", %{"post" => params}, socket) do
    form =
      socket.assigns.post
      |> Blog.change_post(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"post" => params}, socket) do
    save_post(socket, socket.assigns.action, params)
  end

  defp save_post(socket, :new, params) do
    case Blog.create_post(params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_post(socket, :edit, params) do
    case Blog.update_post(socket.assigns.post, params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
```

## Function Component Pattern

```elixir
defmodule MyAppWeb.Components.PostCard do
  use Phoenix.Component

  attr :post, :map, required: true
  attr :current_user_id, :integer, default: nil
  attr :class, :string, default: ""
  slot :actions

  def post_card(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow-md p-4", @class]}>
      <h2 class="font-bold"><%= @post.title %></h2>
      <p class="text-gray-600 mt-2"><%= @post.body %></p>
      <div class="mt-4">
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  # Helper for status classes
  defp status_class(:draft), do: "bg-yellow-100 text-yellow-800"
  defp status_class(:published), do: "bg-green-100 text-green-800"
  defp status_class(_), do: "bg-gray-100 text-gray-800"
end
```

## Migration Pattern

```elixir
defmodule MyApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text
      add :status, :string, default: "draft"
      add :deleted_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
    create index(:posts, [:status])
    create index(:posts, [:deleted_at])
  end
end
```

**Join table:**
```elixir
def change do
  create table(:post_likes) do
    add :post_id, references(:posts, on_delete: :delete_all), null: false
    add :user_id, references(:users, on_delete: :delete_all), null: false
    timestamps(type: :utc_datetime)
  end

  create index(:post_likes, [:post_id])
  create index(:post_likes, [:user_id])
  create unique_index(:post_likes, [:post_id, :user_id])
end
```

**on_delete options:**
- `:delete_all` - Cascade delete owned resources
- `:nilify_all` - Set NULL for optional references
- `:restrict` - Prevent deletion if references exist

## Router Pattern

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", MyAppWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{MyAppWeb.UserAuth, :mount_current_user}] do
      live "/posts", PostLive.Index, :index
      live "/posts/:id", PostLive.Show, :show
    end
  end

  # Authenticated routes
  scope "/", MyAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do
      live "/posts/new", PostLive.Index, :new
      live "/posts/:id/edit", PostLive.Show, :edit
    end
  end

  # Admin routes
  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :admin,
      on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated},
                 {MyAppWeb.AdminAuth, :ensure_admin}] do
      live "/users", UserLive.Index
    end
  end
end
```

## Testing Pattern

```elixir
defmodule MyApp.BlogTest do
  use MyApp.DataCase
  alias MyApp.Blog

  describe "posts" do
    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Blog.list_posts() == [post]
    end

    test "create_post/1 with valid data" do
      user = user_fixture()
      attrs = %{title: "Title", body: "Body", user_id: user.id}
      assert {:ok, %Post{title: "Title"}} = Blog.create_post(attrs)
    end

    test "update_post_with_ownership/3 unauthorized" do
      post = post_fixture()
      other_user = user_fixture()
      assert {:error, :unauthorized} =
        Blog.update_post_with_ownership(post, %{title: "New"}, other_user.id)
    end
  end
end
```

**LiveView test:**
```elixir
defmodule MyAppWeb.PostLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders posts", %{conn: conn} do
    post = post_fixture()
    {:ok, view, html} = live(conn, ~p"/posts")

    assert html =~ post.title
    assert has_element?(view, "h2", post.title)
  end

  test "deletes post", %{conn: conn, user: user} do
    post = post_fixture(user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/posts")

    assert view
           |> element("button", "Delete")
           |> render_click()

    refute has_element?(view, "h2", post.title)
  end
end
```

## Quick Reference

### Mix Commands
```bash
mix phx.new my_app              # New project
mix phx.server                  # Start server
iex -S mix phx.server           # Start with IEx
mix ecto.create                 # Create database
mix ecto.migrate                # Run migrations
mix ecto.rollback               # Rollback last migration
mix ecto.gen.migration name     # Generate migration
mix phx.gen.live Blog Post posts  # Generate LiveView CRUD
mix phx.gen.auth Accounts User users  # Auth system
mix test                        # Run tests
mix format                      # Format code
```

### Common Validations
```elixir
|> validate_required([:field])
|> validate_length(:field, min: 3, max: 255)
|> validate_format(:email, ~r/@/)
|> validate_inclusion(:status, [:a, :b])
|> validate_number(:amount, greater_than: 0)
|> validate_confirmation(:password)
|> unsafe_validate_unique(:email, Repo)
|> unique_constraint(:email)
|> unique_constraint([:post_id, :user_id])
|> foreign_key_constraint(:user_id)
```

### Ecto Query
```elixir
from p in Post,
  where: p.status == :published,
  where: is_nil(p.deleted_at),
  order_by: [desc: p.inserted_at],
  limit: 10,
  preload: [:user]
```

## References

- **references/best-practices.md** - N+1 prevention, form handling, role checking, safe deletion
- **references/liveview-patterns.md** - Streams, uploads, JS hooks
- **references/ecto-patterns.md** - Advanced queries, transactions
- **references/testing-patterns.md** - Test helpers, factories
