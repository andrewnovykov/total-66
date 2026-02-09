# Advanced Ecto Patterns

Detailed patterns for Ecto schemas, queries, and database operations.

## Table of Contents

1. [Schema Patterns](#schema-patterns)
2. [Changeset Patterns](#changeset-patterns)
3. [Query Composition](#query-composition)
4. [Transactions](#transactions)
5. [Aggregations](#aggregations)
6. [Preloading Strategies](#preloading-strategies)

## Schema Patterns

### Complete Schema Example

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @activity_types ["created", "updated", "published"]

  schema "posts" do
    field :title, :string
    field :body, :text
    field :slug, :string
    field :views, :integer, default: 0
    field :metadata, :map, default: %{}

    # Enum fields
    field :status, Ecto.Enum,
      values: [:draft, :published, :archived],
      default: :draft

    field :visibility, Ecto.Enum,
      values: [:public, :private, :friends],
      default: :public

    # Timestamps
    field :published_at, :utc_datetime
    field :deleted_at, :utc_datetime

    # Flags
    field :is_featured, :boolean, default: false
    field :is_pinned, :boolean, default: false

    # Associations
    belongs_to :user, MyApp.Accounts.User
    belongs_to :category, MyApp.Blog.Category

    has_many :comments, MyApp.Blog.Comment
    has_many :likes, MyApp.Blog.PostLike
    has_many :likers, through: [:likes, :user]

    has_many :post_tags, MyApp.Blog.PostTag
    many_to_many :tags, MyApp.Blog.Tag, join_through: "post_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :status, :visibility, :category_id, :user_id,
                    :is_featured, :is_pinned, :metadata])
    |> validate_required([:title, :body, :user_id])
    |> validate_length(:title, min: 3, max: 255)
    |> generate_slug()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:category_id)
  end

  def publish_changeset(post) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    post
    |> change(status: :published, published_at: now)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil -> changeset
      title ->
        slug = title
               |> String.downcase()
               |> String.replace(~r/[^a-z0-9\s-]/, "")
               |> String.replace(~r/\s+/, "-")
               |> String.slice(0, 100)

        put_change(changeset, :slug, "#{slug}-#{:rand.uniform(9999)}")
    end
  end
end
```

### Join Table Schema

```elixir
defmodule MyApp.Blog.PostLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_likes" do
    belongs_to :post, MyApp.Blog.Post
    belongs_to :user, MyApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:post_id, :user_id])
    |> validate_required([:post_id, :user_id])
    |> validate_not_self_like()
    |> unique_constraint([:post_id, :user_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_not_self_like(changeset) do
    # Prevent users from liking their own posts
    # This requires loading the post to check ownership
    changeset
  end
end
```

### Self-Referential Schema (Hierarchies)

```elixir
defmodule MyApp.Blog.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :depth, :integer, default: 0

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :parent_id])
    |> validate_required([:name, :slug])
    |> validate_not_self_parent()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:parent_id)
  end

  defp validate_not_self_parent(changeset) do
    parent_id = get_field(changeset, :parent_id)
    id = get_field(changeset, :id)

    if parent_id && id && parent_id == id do
      add_error(changeset, :parent_id, "cannot be parent of itself")
    else
      changeset
    end
  end
end
```

## Changeset Patterns

### Multiple Changesets for Different Use Cases

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string
    field :name, :string
    field :bio, :string
    field :confirmed_at, :utc_datetime
  end

  # Basic profile updates (no password)
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :bio])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
  end

  # Registration (with password)
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :name])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_required([:name])
  end

  # Email change
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      changeset -> add_error(changeset, :email, "did not change")
    end
  end

  # Password change
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match")
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "must have lowercase")
    |> validate_format(:password, ~r/[A-Z]/, message: "must have uppercase")
    |> validate_format(:password, ~r/[0-9]/, message: "must have number")
    |> maybe_hash_password(opts)
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, MyApp.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    hash = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
```

### Conditional Validations

```elixir
defmodule MyApp.Blog.Post do
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :status, :failure_reason, :failed_at])
    |> validate_required([:title, :body])
    |> validate_failure_fields()
  end

  defp validate_failure_fields(changeset) do
    status = get_field(changeset, :status)
    failure_reason = get_field(changeset, :failure_reason)

    case {status, failure_reason} do
      {:failed, nil} ->
        add_error(changeset, :failure_reason, "required when status is failed")

      {:failed, ""} ->
        add_error(changeset, :failure_reason, "required when status is failed")

      _ ->
        changeset
    end
  end
end
```

## Query Composition

### Dynamic Query Building

```elixir
defmodule MyApp.Blog do
  import Ecto.Query

  def list_posts(opts \\ []) do
    Post
    |> base_query()
    |> filter_by_status(opts[:status])
    |> filter_by_visibility(opts[:visibility])
    |> filter_by_user(opts[:user_id])
    |> filter_by_category(opts[:category_id])
    |> search_by_text(opts[:search])
    |> filter_by_date_range(opts[:from], opts[:to])
    |> order_by_field(opts[:sort_by], opts[:sort_order])
    |> paginate(opts[:page], opts[:per_page])
    |> Repo.all()
    |> Repo.preload([:user, :category])
  end

  defp base_query(query) do
    from p in query, where: is_nil(p.deleted_at)
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status) do
    from p in query, where: p.status == ^status
  end

  defp filter_by_visibility(query, nil), do: query
  defp filter_by_visibility(query, visibility) do
    from p in query, where: p.visibility == ^visibility
  end

  defp filter_by_user(query, nil), do: query
  defp filter_by_user(query, user_id) do
    from p in query, where: p.user_id == ^user_id
  end

  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, category_id) do
    from p in query, where: p.category_id == ^category_id
  end

  defp search_by_text(query, nil), do: query
  defp search_by_text(query, ""), do: query
  defp search_by_text(query, search) do
    term = "%#{search}%"
    from p in query,
      where: ilike(p.title, ^term) or ilike(p.body, ^term)
  end

  defp filter_by_date_range(query, nil, nil), do: query
  defp filter_by_date_range(query, from, nil) do
    from p in query, where: p.inserted_at >= ^from
  end
  defp filter_by_date_range(query, nil, to) do
    from p in query, where: p.inserted_at <= ^to
  end
  defp filter_by_date_range(query, from, to) do
    from p in query, where: p.inserted_at >= ^from and p.inserted_at <= ^to
  end

  defp order_by_field(query, nil, _), do: from(p in query, order_by: [desc: p.inserted_at])
  defp order_by_field(query, :views, :asc), do: from(p in query, order_by: [asc: p.views])
  defp order_by_field(query, :views, _), do: from(p in query, order_by: [desc: p.views])
  defp order_by_field(query, :title, :desc), do: from(p in query, order_by: [desc: p.title])
  defp order_by_field(query, :title, _), do: from(p in query, order_by: [asc: p.title])
  defp order_by_field(query, _, _), do: from(p in query, order_by: [desc: p.inserted_at])

  defp paginate(query, nil, _), do: query
  defp paginate(query, page, per_page) do
    per_page = per_page || 20
    offset = (page - 1) * per_page

    from p in query,
      limit: ^per_page,
      offset: ^offset
  end
end
```

### Subqueries

```elixir
def list_posts_with_comment_count do
  comment_counts =
    from c in Comment,
      group_by: c.post_id,
      select: %{post_id: c.post_id, count: count(c.id)}

  from p in Post,
    left_join: cc in subquery(comment_counts),
    on: cc.post_id == p.id,
    select: %{post: p, comment_count: coalesce(cc.count, 0)}
  |> Repo.all()
end

def list_users_with_post_count do
  post_counts =
    from p in Post,
      where: is_nil(p.deleted_at),
      group_by: p.user_id,
      select: %{user_id: p.user_id, count: count(p.id)}

  from u in User,
    left_join: pc in subquery(post_counts),
    on: pc.user_id == u.id,
    select: %{user: u, post_count: coalesce(pc.count, 0)},
    order_by: [desc: coalesce(pc.count, 0)]
  |> Repo.all()
end
```

## Transactions

### Basic Transaction

```elixir
def create_post_with_tags(attrs, tag_ids) do
  Repo.transaction(fn ->
    with {:ok, post} <- create_post(attrs),
         :ok <- attach_tags(post, tag_ids) do
      post
    else
      {:error, reason} -> Repo.rollback(reason)
    end
  end)
end

defp attach_tags(_post, []), do: :ok
defp attach_tags(post, tag_ids) do
  tag_ids
  |> Enum.each(fn tag_id ->
    %PostTag{}
    |> PostTag.changeset(%{post_id: post.id, tag_id: tag_id})
    |> Repo.insert!()
  end)

  :ok
end
```

### Multi for Complex Transactions

```elixir
alias Ecto.Multi

def transfer_ownership(post, from_user, to_user) do
  Multi.new()
  |> Multi.update(:post, Post.changeset(post, %{user_id: to_user.id}))
  |> Multi.run(:log_transfer, fn _repo, %{post: post} ->
    create_activity_log(%{
      type: "ownership_transfer",
      post_id: post.id,
      from_user_id: from_user.id,
      to_user_id: to_user.id
    })
  end)
  |> Multi.run(:notify_users, fn _repo, %{post: post} ->
    notify_ownership_change(post, from_user, to_user)
    {:ok, :notified}
  end)
  |> Repo.transaction()
  |> case do
    {:ok, %{post: post}} -> {:ok, post}
    {:error, _step, reason, _changes} -> {:error, reason}
  end
end
```

## Aggregations

```elixir
def post_statistics(user_id) do
  from(p in Post,
    where: p.user_id == ^user_id and is_nil(p.deleted_at),
    select: %{
      total: count(p.id),
      published: filter(count(p.id), p.status == :published),
      draft: filter(count(p.id), p.status == :draft),
      total_views: sum(p.views),
      avg_views: avg(p.views)
    }
  )
  |> Repo.one()
end

def top_categories_by_posts do
  from(p in Post,
    join: c in Category, on: c.id == p.category_id,
    where: is_nil(p.deleted_at),
    group_by: c.id,
    select: %{category: c, post_count: count(p.id)},
    order_by: [desc: count(p.id)],
    limit: 10
  )
  |> Repo.all()
end
```

## Preloading Strategies

```elixir
# Simple preload
def get_post!(id) do
  Repo.get!(Post, id)
  |> Repo.preload([:user, :category, :tags])
end

# Preload with ordering
def list_posts_with_comments do
  Post
  |> Repo.all()
  |> Repo.preload(comments: from(c in Comment, order_by: [desc: c.inserted_at]))
end

# Preload with filtering
def list_posts_with_published_comments do
  Post
  |> Repo.all()
  |> Repo.preload(comments: from(c in Comment, where: c.status == :published))
end

# Nested preload
def get_post_full!(id) do
  Repo.get!(Post, id)
  |> Repo.preload([
    :user,
    :category,
    :tags,
    comments: [:user, replies: :user]
  ])
end

# Join-based preload (more efficient for filtering)
def list_posts_by_tag(tag_name) do
  from(p in Post,
    join: pt in PostTag, on: pt.post_id == p.id,
    join: t in Tag, on: t.id == pt.tag_id,
    where: t.name == ^tag_name,
    preload: [:user, :category]
  )
  |> Repo.all()
end
```
