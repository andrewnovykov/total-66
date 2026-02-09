defmodule HeadsUpWeb.Admin.GroupsLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Groups
  alias HeadsUp.Group
  import HeadsUpWeb.Helpers.RoleHelper

  def mount(_params, _session, socket) do
    # Check if user is admin using centralized helper
    if not is_admin?(socket.assigns.current_user) do
      {:ok,
       socket
       |> put_flash(:error, "Access denied. Admin privileges required.")
       |> redirect(to: ~p"/")}
    else
      groups = Groups.list_groups() |> add_goal_counts()
      changeset = Groups.change_group(%Group{})

      socket =
        socket
        |> assign(:groups, groups)
        |> assign(:show_create_modal, false)
        |> assign(:show_edit_modal, false)
        |> assign(:form, to_form(changeset, as: "group"))
        |> assign(:editing_group, nil)

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <.link
              navigate={~p"/"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Home
            </.link>

            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              Admin
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Goal Categories
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Manage goal categories that help users organize and discover goals.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-tag" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Action Bar --%>
        <div class="flex items-center justify-between mb-8">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-tag" class="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p class="font-extrabold text-slate-900">{length(@groups)} Categories</p>
              <p class="text-sm text-slate-400">Total goal categories</p>
            </div>
          </div>
          <button
            phx-click="show_create_modal"
            class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
          >
            <.icon name="hero-plus" class="w-5 h-5" /> New Category
          </button>
        </div>

        <%!-- Categories List --%>
        <%= if Enum.empty?(@groups) do %>
          <HeadsUpWeb.Components.UI.EmptyState.empty_state
            icon="hero-tag"
            title="No categories yet"
            message="Create your first goal category to help users organize their goals."
          >
            <:action>
              <button
                phx-click="show_create_modal"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Create Category
              </button>
            </:action>
          </HeadsUpWeb.Components.UI.EmptyState.empty_state>
        <% else %>
          <div class="space-y-4">
            <%= for group <- @groups do %>
              <HeadsUpWeb.Components.UI.Card.card>
                <div class="flex items-center gap-5">
                  <%!-- Image / Fallback --%>
                  <%= if group.image_path do %>
                    <img
                      src={group.image_path}
                      alt={group.name}
                      class="w-12 h-12 rounded-2xl object-cover flex-shrink-0"
                    />
                  <% else %>
                    <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center flex-shrink-0">
                      <span class="text-white text-lg font-bold">{String.first(group.name)}</span>
                    </div>
                  <% end %>

                  <%!-- Info --%>
                  <div class="flex-1 min-w-0">
                    <h3 class="font-extrabold text-slate-900 text-base">{group.name}</h3>
                    <p class="text-sm text-slate-400 truncate">
                      {group.description || "No description"}
                    </p>
                  </div>

                  <%!-- Status Badge --%>
                  <span class={[
                    "px-3 py-1.5 text-xs font-bold rounded-full flex-shrink-0",
                    status_badge_class(group.status)
                  ]}>
                    {String.capitalize(to_string(group.status))}
                  </span>

                  <%!-- Goal Count --%>
                  <span class={[
                    "px-3 py-1.5 text-xs font-bold rounded-full flex-shrink-0",
                    if(group.goal_count > 0,
                      do: "bg-blue-50 text-blue-600",
                      else: "bg-slate-100 text-slate-400"
                    )
                  ]}>
                    {group.goal_count} {if group.goal_count == 1, do: "goal", else: "goals"}
                  </span>

                  <%!-- Actions --%>
                  <div class="flex items-center gap-2 flex-shrink-0">
                    <button
                      phx-click="edit_group"
                      phx-value-id={group.id}
                      class="p-2.5 rounded-xl text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                      title="Edit"
                    >
                      <.icon name="hero-pencil-square" class="w-5 h-5" />
                    </button>
                    <button
                      phx-click="delete_group"
                      phx-value-id={group.id}
                      data-confirm={
                        if group.goal_count > 0,
                          do:
                            "This category has #{group.goal_count} goal(s). You cannot delete it until goals are reassigned.",
                          else: "Are you sure you want to delete this category?"
                      }
                      class={[
                        "p-2.5 rounded-xl transition-colors",
                        if(group.goal_count > 0,
                          do: "text-slate-300 cursor-not-allowed",
                          else: "text-slate-400 hover:text-red-600 hover:bg-red-50"
                        )
                      ]}
                      title="Delete"
                    >
                      <.icon name="hero-trash" class="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Quick Stats --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Stats</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-tag" class="w-7 h-7 text-blue-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@groups)}</p>
                <p class="text-xs text-slate-400 font-medium">Total Categories</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-7 h-7 text-green-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.count(@groups, &(&1.status == :published))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Published</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-7 h-7 text-indigo-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.sum(Enum.map(@groups, & &1.goal_count))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Total Goals</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Admin Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Admin Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/admin/challenge-categories"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-trophy" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Challenge Categories
              </span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/goals-category"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-squares-2x2" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Browse Categories
              </span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
    </div>

    <%!-- Create Modal --%>
    <%= if @show_create_modal do %>
      <div class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
        <div class="bg-white rounded-[32px] p-8 w-full max-w-lg mx-4 soft-shadow">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-extrabold text-slate-900">Create New Category</h2>
            <button
              phx-click="hide_create_modal"
              class="text-slate-400 hover:text-slate-600 p-2 rounded-xl hover:bg-slate-50 transition-colors"
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>

          <.form for={@form} phx-submit="create_group" class="space-y-5">
            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Name <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:name]}
                type="text"
                placeholder="Category name"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Description <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:description]}
                type="textarea"
                placeholder="Category description"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Image URL <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:image_path]}
                type="text"
                placeholder="https://example.com/image.jpg"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">Status</label>
              <.input
                field={@form[:status]}
                type="select"
                options={[{"Published", "published"}, {"Unpublished", "unpublished"}]}
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div class="flex gap-3 pt-2">
              <button
                type="submit"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Create Category
              </button>
              <button
                type="button"
                phx-click="hide_create_modal"
                class="px-6 py-3 bg-slate-100 text-slate-600 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>

    <%!-- Edit Modal --%>
    <%= if @show_edit_modal do %>
      <div class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
        <div class="bg-white rounded-[32px] p-8 w-full max-w-lg mx-4 soft-shadow">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-extrabold text-slate-900">Edit Category</h2>
            <button
              phx-click="hide_edit_modal"
              class="text-slate-400 hover:text-slate-600 p-2 rounded-xl hover:bg-slate-50 transition-colors"
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>

          <.form for={@form} phx-submit="update_group" class="space-y-5">
            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Name <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:name]}
                type="text"
                placeholder="Category name"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Description <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:description]}
                type="textarea"
                placeholder="Category description"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">
                Image URL <span class="text-red-400">*</span>
              </label>
              <.input
                field={@form[:image_path]}
                type="text"
                placeholder="https://example.com/image.jpg"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-slate-700 mb-2">Status</label>
              <.input
                field={@form[:status]}
                type="select"
                options={[{"Published", "published"}, {"Unpublished", "unpublished"}]}
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div class="flex gap-3 pt-2">
              <button
                type="submit"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-check" class="w-4 h-4" /> Update Category
              </button>
              <button
                type="button"
                phx-click="hide_edit_modal"
                class="px-6 py-3 bg-slate-100 text-slate-600 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_event("show_create_modal", _params, socket) do
    changeset = Groups.change_group(%Group{})
    {:noreply, assign(socket, show_create_modal: true, form: to_form(changeset, as: "group"))}
  end

  def handle_event("hide_create_modal", _params, socket) do
    {:noreply, assign(socket, show_create_modal: false)}
  end

  def handle_event("create_group", %{"group" => group_params}, socket) do
    case Groups.create_group(group_params) do
      {:ok, _group} ->
        groups = Groups.list_groups() |> add_goal_counts()

        socket =
          socket
          |> assign(:groups, groups)
          |> assign(:show_create_modal, false)
          |> put_flash(:info, "Category created successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "group"))}
    end
  end

  def handle_event("edit_group", %{"id" => id}, socket) do
    group = Groups.get_group!(id)
    changeset = Groups.change_group(group)

    socket =
      socket
      |> assign(:show_edit_modal, true)
      |> assign(:editing_group, group)
      |> assign(:form, to_form(changeset, as: "group"))

    {:noreply, socket}
  end

  def handle_event("hide_edit_modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: false, editing_group: nil)}
  end

  def handle_event("update_group", %{"group" => group_params}, socket) do
    case Groups.update_group(socket.assigns.editing_group, group_params) do
      {:ok, _group} ->
        groups = Groups.list_groups() |> add_goal_counts()

        socket =
          socket
          |> assign(:groups, groups)
          |> assign(:show_edit_modal, false)
          |> assign(:editing_group, nil)
          |> put_flash(:info, "Category updated successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "group"))}
    end
  end

  def handle_event("delete_group", %{"id" => id}, socket) do
    group = Groups.get_group!(id)

    case Groups.safe_delete_group(group) do
      {:ok, _group} ->
        groups = Groups.list_groups() |> add_goal_counts()

        socket =
          socket
          |> assign(:groups, groups)
          |> put_flash(:info, "Category deleted successfully!")

        {:noreply, socket}

      {:error, :has_goals, count} ->
        socket =
          put_flash(
            socket,
            :error,
            "Cannot delete category \"#{group.name}\". It has #{count} goal(s) associated with it. " <>
              "Please reassign or delete those goals first."
          )

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Failed to delete category. Please try again.")
        {:noreply, socket}
    end
  end

  defp add_goal_counts(groups) do
    group_ids = Enum.map(groups, & &1.id)
    counts_map = Groups.goal_counts_by_group_ids(group_ids)

    Enum.map(groups, fn group ->
      Map.put(group, :goal_count, Map.get(counts_map, group.id, 0))
    end)
  end

  defp status_badge_class(:published), do: "bg-green-50 text-green-600"
  defp status_badge_class(:unpublished), do: "bg-slate-100 text-slate-500"
  defp status_badge_class(_), do: "bg-slate-100 text-slate-500"
end
