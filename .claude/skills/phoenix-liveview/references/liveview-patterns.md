# Advanced LiveView Patterns

Detailed patterns for Phoenix LiveView development.

## Table of Contents

1. [Streams for Large Lists](#streams-for-large-lists)
2. [File Uploads](#file-uploads)
3. [JS Commands](#js-commands)
4. [PubSub Real-time Updates](#pubsub-real-time-updates)
5. [Form Handling](#form-handling)
6. [Navigation Patterns](#navigation-patterns)
7. [Error Handling](#error-handling)

## Streams for Large Lists

Use streams instead of assigns for large, frequently-changing lists.

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> stream(:posts, Blog.list_posts(), dom_id: &"post-#{&1.id}")}
end

def handle_info({:post_created, post}, socket) do
  {:noreply, stream_insert(socket, :posts, post, at: 0)}
end

def handle_info({:post_updated, post}, socket) do
  {:noreply, stream_insert(socket, :posts, post)}
end

def handle_info({:post_deleted, post}, socket) do
  {:noreply, stream_delete(socket, :posts, post)}
end

def render(assigns) do
  ~H"""
  <div id="posts" phx-update="stream">
    <div :for={{dom_id, post} <- @streams.posts} id={dom_id}>
      <%= post.title %>
    </div>
  </div>
  """
end
```

**Stream operations:**
- `stream/4` - Initialize stream
- `stream_insert/4` - Insert or update item (`at: 0` for prepend, `at: -1` for append)
- `stream_delete/3` - Remove item
- `stream/4` with `reset: true` - Replace entire stream

## File Uploads

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> allow_upload(:avatar,
     accept: ~w(.jpg .jpeg .png .gif),
     max_entries: 1,
     max_file_size: 5_000_000
   )}
end

def handle_event("validate", _params, socket) do
  {:noreply, socket}
end

def handle_event("save", _params, socket) do
  uploaded_files =
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
      dest = Path.join("priv/static/uploads", "#{entry.uuid}-#{entry.client_name}")
      File.cp!(path, dest)
      {:ok, "/uploads/#{Path.basename(dest)}"}
    end)

  case uploaded_files do
    [image_path] ->
      # Save image_path to database
      {:noreply, put_flash(socket, :info, "Uploaded")}

    [] ->
      {:noreply, put_flash(socket, :error, "No file selected")}
  end
end

def render(assigns) do
  ~H"""
  <form phx-submit="save" phx-change="validate">
    <.live_file_input upload={@uploads.avatar} />

    <%= for entry <- @uploads.avatar.entries do %>
      <div class="flex items-center gap-4">
        <.live_img_preview entry={entry} class="w-20 h-20 rounded" />
        <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref}>
          Cancel
        </button>
      </div>

      <%= for err <- upload_errors(@uploads.avatar, entry) do %>
        <p class="text-red-500"><%= error_to_string(err) %></p>
      <% end %>
    <% end %>

    <button type="submit">Upload</button>
  </form>
  """
end

def handle_event("cancel-upload", %{"ref" => ref}, socket) do
  {:noreply, cancel_upload(socket, :avatar, ref)}
end

defp error_to_string(:too_large), do: "File is too large"
defp error_to_string(:not_accepted), do: "File type not accepted"
defp error_to_string(:too_many_files), do: "Too many files"
```

## JS Commands

Client-side interactions without server roundtrip.

```elixir
def render(assigns) do
  ~H"""
  <div>
    <button phx-click={JS.toggle(to: "#menu")}>
      Toggle Menu
    </button>

    <div id="menu" class="hidden">
      Menu content
    </div>

    <button phx-click={
      JS.push("delete", value: %{id: @item.id})
      |> JS.hide(to: "#item-#{@item.id}", transition: "fade-out")
    }>
      Delete with Animation
    </button>

    <button phx-click={
      JS.add_class("bg-blue-500", to: "#target")
      |> JS.remove_class("bg-gray-500", to: "#target")
    }>
      Change Color
    </button>
  </div>
  """
end
```

**Common JS commands:**
- `JS.toggle/1` - Show/hide element
- `JS.show/1`, `JS.hide/1` - Visibility
- `JS.push/2` - Trigger server event
- `JS.add_class/2`, `JS.remove_class/2` - CSS classes
- `JS.set_attribute/2`, `JS.remove_attribute/2`
- `JS.dispatch/2` - Custom events
- `JS.focus/1`, `JS.focus_first/1`
- `JS.navigate/1`, `JS.patch/1`

## PubSub Real-time Updates

```elixir
# In context (publisher)
defmodule MyApp.Blog do
  def create_post(attrs) do
    case %Post{} |> Post.changeset(attrs) |> Repo.insert() do
      {:ok, post} ->
        Phoenix.PubSub.broadcast(MyApp.PubSub, "posts", {:post_created, post})
        {:ok, post}

      error ->
        error
    end
  end
end

# In LiveView (subscriber)
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "posts")
    Phoenix.PubSub.subscribe(MyApp.PubSub, "user:#{socket.assigns.current_user.id}")
  end

  {:ok, assign(socket, :posts, Blog.list_posts())}
end

def handle_info({:post_created, post}, socket) do
  {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
end

def handle_info({:post_updated, post}, socket) do
  {:noreply,
   update(socket, :posts, fn posts ->
     Enum.map(posts, fn p -> if p.id == post.id, do: post, else: p end)
   end)}
end

def handle_info({:notification, message}, socket) do
  {:noreply, put_flash(socket, :info, message)}
end
```

**Topic naming conventions:**
- `"posts"` - Global topic for all posts
- `"posts:#{post_id}"` - Specific post updates
- `"user:#{user_id}"` - User-specific notifications
- `"room:#{room_id}"` - Chat room messages

## Form Handling

### Standard Form with Changeset

```elixir
def mount(_params, _session, socket) do
  changeset = Blog.change_post(%Post{})
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("validate", %{"post" => params}, socket) do
  form =
    %Post{}
    |> Blog.change_post(params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, :form, form)}
end

def handle_event("save", %{"post" => params}, socket) do
  case Blog.create_post(params) do
    {:ok, _post} ->
      {:noreply,
       socket
       |> put_flash(:info, "Created")
       |> push_navigate(to: ~p"/posts")}

    {:error, changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end

def render(assigns) do
  ~H"""
  <.simple_form for={@form} phx-change="validate" phx-submit="save">
    <.input field={@form[:title]} label="Title" />
    <.input field={@form[:body]} type="textarea" label="Body" />
    <.input field={@form[:status]} type="select" label="Status"
      options={[{"Draft", :draft}, {"Published", :published}]} />
    <:actions>
      <.button>Save</.button>
    </:actions>
  </.simple_form>
  """
end
```

### Form Without Changeset

```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket, form: to_form(%{"query" => ""}))}
end

def handle_event("search", %{"query" => query}, socket) do
  results = Blog.search_posts(query)
  {:noreply, assign(socket, results: results)}
end
```

### Inline Editing

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:editing, false)
   |> assign(:form, to_form(%{"value" => socket.assigns.item.value}))}
end

def handle_event("edit", _params, socket) do
  {:noreply, assign(socket, :editing, true)}
end

def handle_event("cancel", _params, socket) do
  {:noreply, assign(socket, :editing, false)}
end

def handle_event("save", %{"value" => value}, socket) do
  case update_item(socket.assigns.item, value) do
    {:ok, item} ->
      {:noreply,
       socket
       |> assign(:item, item)
       |> assign(:editing, false)}

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Failed")}
  end
end
```

## Navigation Patterns

### Push Navigate vs Push Patch

```elixir
# push_navigate - Full LiveView reload (new mount)
{:noreply, push_navigate(socket, to: ~p"/posts")}

# push_patch - Same LiveView, handle_params called
{:noreply, push_patch(socket, to: ~p"/posts?page=2")}

# With replace (no browser history entry)
{:noreply, push_navigate(socket, to: ~p"/posts", replace: true)}
```

### Handle Params for URL State

```elixir
def handle_params(params, _url, socket) do
  page = String.to_integer(params["page"] || "1")
  posts = Blog.list_posts(page: page)

  {:noreply,
   socket
   |> assign(:page, page)
   |> assign(:posts, posts)}
end
```

### Modal Pattern with Live Actions

```elixir
# In router
live "/posts", PostLive.Index, :index
live "/posts/new", PostLive.Index, :new
live "/posts/:id/edit", PostLive.Index, :edit

# In LiveView
def handle_params(params, _url, socket) do
  {:noreply, apply_action(socket, socket.assigns.live_action, params)}
end

defp apply_action(socket, :index, _params) do
  assign(socket, :post, nil)
end

defp apply_action(socket, :new, _params) do
  assign(socket, :post, %Post{})
end

defp apply_action(socket, :edit, %{"id" => id}) do
  assign(socket, :post, Blog.get_post!(id))
end

def render(assigns) do
  ~H"""
  <div>
    <.link patch={~p"/posts/new"}>New Post</.link>

    <.modal :if={@live_action in [:new, :edit]} id="post-modal"
      show on_cancel={JS.patch(~p"/posts")}>
      <.live_component
        module={FormComponent}
        id={@post.id || :new}
        action={@live_action}
        post={@post}
        patch={~p"/posts"}
      />
    </.modal>
  </div>
  """
end
```

## Error Handling

### Context Error Pattern

```elixir
def handle_event("action", params, socket) do
  case Context.do_action(params, socket.assigns.current_user.id) do
    {:ok, result} ->
      {:noreply,
       socket
       |> put_flash(:info, "Success")
       |> assign(:result, result)}

    {:error, :unauthorized} ->
      {:noreply, put_flash(socket, :error, "Not authorized")}

    {:error, :not_found} ->
      {:noreply,
       socket
       |> put_flash(:error, "Not found")
       |> push_navigate(to: ~p"/items")}

    {:error, :frozen} ->
      {:noreply, put_flash(socket, :error, "Item is frozen")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
```

### Mount Error Handling

```elixir
def mount(%{"id" => id}, _session, socket) do
  case Blog.get_post(id) do
    nil ->
      {:ok,
       socket
       |> put_flash(:error, "Post not found")
       |> push_navigate(to: ~p"/posts")}

    post ->
      if can_view?(socket.assigns[:current_user], post) do
        {:ok, assign(socket, :post, post)}
      else
        {:ok,
         socket
         |> put_flash(:error, "Access denied")
         |> push_navigate(to: ~p"/posts")}
      end
  end
end
```

### Exception Handling

```elixir
def handle_event("risky_action", params, socket) do
  try do
    result = perform_risky_action(params)
    {:noreply, assign(socket, :result, result)}
  rescue
    e in RuntimeError ->
      {:noreply, put_flash(socket, :error, "Error: #{e.message}")}
  end
end
```
