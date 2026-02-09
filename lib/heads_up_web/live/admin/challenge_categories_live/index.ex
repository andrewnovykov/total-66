defmodule HeadsUpWeb.Admin.ChallengeCategoriesLive.Index do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Challenges
  alias HeadsUp.Challenges.ChallengeCategory

  @impl true
  def mount(_params, _session, socket) do
    categories = Challenges.list_categories()

    {:ok,
     socket
     |> assign(:page_title, "Challenge Categories")
     |> assign(:categories, categories)
     |> assign(:show_form, false)
     |> assign(:editing_category, nil)
     |> assign(:form, to_form(Challenges.change_category(%ChallengeCategory{})))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    category = Challenges.get_category!(id)

    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:editing_category, category)
    |> assign(:show_form, true)
    |> assign(:form, to_form(Challenges.change_category(category)))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:editing_category, nil)
    |> assign(:show_form, true)
    |> assign(:form, to_form(Challenges.change_category(%ChallengeCategory{})))
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> assign(:page_title, "Challenge Categories")
    |> assign(:show_form, false)
    |> assign(:editing_category, nil)
  end

  @impl true
  def handle_event("new", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_category, nil)
     |> assign(:form, to_form(Challenges.change_category(%ChallengeCategory{})))}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    category = Challenges.get_category!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_category, category)
     |> assign(:form, to_form(Challenges.change_category(category)))}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:editing_category, nil)}
  end

  @impl true
  def handle_event("validate", %{"challenge_category" => params}, socket) do
    category = socket.assigns.editing_category || %ChallengeCategory{}

    form =
      category
      |> Challenges.change_category(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"challenge_category" => params}, socket) do
    save_category(socket, socket.assigns.editing_category, params)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Challenges.get_category!(id)

    case Challenges.delete_category(category, socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category deleted successfully")
         |> assign(:categories, Challenges.list_categories())}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Unauthorized")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete category")}
    end
  end

  defp save_category(socket, nil, params) do
    case Challenges.create_category(params, socket.assigns.current_user) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> assign(:categories, Challenges.list_categories())
         |> assign(:show_form, false)
         |> assign(:editing_category, nil)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Unauthorized")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_category(socket, category, params) do
    case Challenges.update_category(category, params, socket.assigns.current_user) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category updated successfully")
         |> assign(:categories, Challenges.list_categories())
         |> assign(:show_form, false)
         |> assign(:editing_category, nil)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Unauthorized")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
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
              Challenge Categories
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Manage categories for challenges. Create, edit, and organize categories that users will browse.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-squares-2x2" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Action Bar --%>
        <div class="flex items-center justify-between mb-8">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-rectangle-stack" class="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <p class="font-extrabold text-slate-900">{length(@categories)} Categories</p>
              <p class="text-sm text-slate-400">Total managed categories</p>
            </div>
          </div>
          <button
            phx-click="new"
            class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
          >
            <.icon name="hero-plus" class="w-5 h-5" /> New Category
          </button>
        </div>

        <%!-- Form Card (Create/Edit) --%>
        <%= if @show_form do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <div class="flex items-center justify-between mb-6">
              <h2 class="text-xl font-extrabold text-slate-900">
                {if @editing_category, do: "Edit Category", else: "New Category"}
              </h2>
              <button
                type="button"
                phx-click="cancel"
                class="text-slate-400 hover:text-slate-600 p-2 rounded-xl hover:bg-slate-50 transition-colors"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>
            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
              <div>
                <label class="block text-sm font-bold text-slate-700 mb-2">
                  Name <span class="text-red-400">*</span>
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  placeholder="Category name"
                  class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
                />
              </div>

              <div>
                <label class="block text-sm font-bold text-slate-700 mb-2">Description</label>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  placeholder="Category description"
                  class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
                  rows="3"
                />
              </div>

              <div>
                <label class="block text-sm font-bold text-slate-700 mb-2">Image URL</label>
                <.input
                  field={@form[:image_path]}
                  type="text"
                  placeholder="https://example.com/image.jpg"
                  class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
                />
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-bold text-slate-700 mb-2">Status</label>
                  <.input
                    field={@form[:status]}
                    type="select"
                    options={[{"Active", :active}, {"Inactive", :inactive}]}
                    class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
                  />
                </div>

                <div>
                  <label class="block text-sm font-bold text-slate-700 mb-2">Order</label>
                  <.input
                    field={@form[:order]}
                    type="number"
                    placeholder="0"
                    class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
                  />
                </div>
              </div>

              <div class="flex gap-3 pt-2">
                <button
                  type="submit"
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
                >
                  <.icon
                    name={if @editing_category, do: "hero-check", else: "hero-plus"}
                    class="w-4 h-4"
                  />
                  {if @editing_category, do: "Update Category", else: "Create Category"}
                </button>
                <button
                  type="button"
                  phx-click="cancel"
                  class="px-6 py-3 bg-slate-100 text-slate-600 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </.form>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Categories List --%>
        <%= if Enum.empty?(@categories) do %>
          <HeadsUpWeb.Components.UI.EmptyState.empty_state
            icon="hero-rectangle-stack"
            title="No categories yet"
            message="Create your first challenge category to get started organizing challenges."
          >
            <:action>
              <button
                phx-click="new"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Create Category
              </button>
            </:action>
          </HeadsUpWeb.Components.UI.EmptyState.empty_state>
        <% else %>
          <div class="space-y-4">
            <%= for category <- @categories do %>
              <HeadsUpWeb.Components.UI.Card.card>
                <div class="flex items-center gap-5">
                  <%!-- Order Badge --%>
                  <div class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center flex-shrink-0">
                    <span class="text-sm font-extrabold text-slate-500">{category.order}</span>
                  </div>

                  <%!-- Image / Fallback --%>
                  <%= if category.image_path do %>
                    <img
                      src={category.image_path}
                      class="w-12 h-12 rounded-2xl object-cover flex-shrink-0"
                      alt={category.name}
                    />
                  <% else %>
                    <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-indigo-400 to-blue-500 flex items-center justify-center flex-shrink-0">
                      <span class="text-white text-lg font-bold">{String.first(category.name)}</span>
                    </div>
                  <% end %>

                  <%!-- Info --%>
                  <div class="flex-1 min-w-0">
                    <h3 class="font-extrabold text-slate-900 text-base">{category.name}</h3>
                    <p class="text-sm text-slate-400 truncate">
                      {category.description || "No description"}
                    </p>
                  </div>

                  <%!-- Status Badge --%>
                  <span class={[
                    "px-3 py-1.5 text-xs font-bold rounded-full flex-shrink-0",
                    if(category.status == :active,
                      do: "bg-green-50 text-green-600",
                      else: "bg-slate-100 text-slate-500"
                    )
                  ]}>
                    {if category.status == :active, do: "Active", else: "Inactive"}
                  </span>

                  <%!-- Actions --%>
                  <div class="flex items-center gap-2 flex-shrink-0">
                    <button
                      phx-click="edit"
                      phx-value-id={category.id}
                      class="p-2.5 rounded-xl text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                      title="Edit"
                    >
                      <.icon name="hero-pencil-square" class="w-5 h-5" />
                    </button>
                    <button
                      phx-click="delete"
                      phx-value-id={category.id}
                      data-confirm="Are you sure you want to delete this category?"
                      class="p-2.5 rounded-xl text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
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
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-rectangle-stack" class="w-7 h-7 text-indigo-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@categories)}</p>
                <p class="text-xs text-slate-400 font-medium">Total Categories</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-7 h-7 text-green-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.count(@categories, &(&1.status == :active))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Active Categories</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-amber-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-pause-circle" class="w-7 h-7 text-amber-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.count(@categories, &(&1.status == :inactive))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Inactive Categories</p>
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
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-tag" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Challenge Categories</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/challenges"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-trophy" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Browse Challenges
              </span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
    </div>
    """
  end
end
