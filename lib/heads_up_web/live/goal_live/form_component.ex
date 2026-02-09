defmodule HeadsUpWeb.GoalLive.FormComponent do
  use HeadsUpWeb, :live_component
  alias HeadsUp.Goals
  import HeadsUpWeb.Helpers.SubscriptionHelper

  def update(%{goal: goal} = assigns, socket) do
    changeset = Goals.change_goal(goal)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"goal" => goal_params}, socket) do
    changeset =
      socket.assigns.goal
      |> Goals.change_goal(goal_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
  end

  def handle_event("save", %{"goal" => goal_params}, socket) do
    save_goal(socket, socket.assigns.action, goal_params)
  end

  defp save_goal(socket, :edit, goal_params) do
    case Goals.update_goal_with_ownership(
           socket.assigns.goal,
           goal_params,
           socket.assigns.current_user_id
         ) do
      {:ok, _goal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Goal updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this goal")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
    end
  end

  defp save_goal(socket, :new, goal_params) do
    # Check subscription limits before creating
    current_user = socket.assigns.current_user
    current_goal_count = length(Goals.list_goals_by_user(current_user.id))

    if not can_create_goal?(current_user, current_goal_count) do
      limit = get_goal_limit(current_user)

      limit_text =
        case limit do
          :unlimited -> "unlimited"
          n -> "#{n}"
        end

      changeset =
        Goals.change_goal(socket.assigns.goal, goal_params)
        |> Ecto.Changeset.add_error(
          :base,
          "You can only create up to #{limit_text} goals with your current subscription (#{get_subscription_display_name(current_user.subscription_type)})"
        )

      {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
    else
      # Add the current user ID to the goal params
      goal_params = Map.put(goal_params, "user_id", socket.assigns.current_user_id)

      case Goals.create_goal(goal_params) do
        {:ok, _goal} ->
          {:noreply,
           socket
           |> put_flash(:info, "Goal created successfully")
           |> push_navigate(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="goal-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-6">
          <%!-- Title --%>
          <div>
            <label for={@form[:title].id} class="block text-sm font-bold text-slate-700 mb-2">
              Goal Title <span class="text-red-400">*</span>
            </label>
            <input
              type="text"
              name={@form[:title].name}
              id={@form[:title].id}
              value={Phoenix.HTML.Form.normalize_value("text", @form[:title].value)}
              placeholder="e.g., Run a Marathon"
              required
              class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
            />
            <.error :for={msg <- Enum.map(@form[:title].errors || [], &translate_error(&1))}>
              {msg}
            </.error>
          </div>

          <%!-- Short Description --%>
          <div>
            <label for={@form[:description].id} class="block text-sm font-bold text-slate-700 mb-2">
              Short Description
            </label>
            <textarea
              name={@form[:description].name}
              id={@form[:description].id}
              rows="2"
              placeholder="Brief description for goal cards..."
              class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500/30 text-base resize-none"
            ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:description].value) %></textarea>
            <.error :for={msg <- Enum.map(@form[:description].errors || [], &translate_error(&1))}>
              {msg}
            </.error>
          </div>

          <%!-- Detailed Description --%>
          <div>
            <label
              for={@form[:big_description].id}
              class="block text-sm font-bold text-slate-700 mb-2"
            >
              Detailed Description <span class="text-slate-400 font-normal">(Optional)</span>
            </label>
            <textarea
              name={@form[:big_description].name}
              id={@form[:big_description].id}
              rows="6"
              placeholder="Write a detailed description of your goal, your motivation, plans, etc..."
              class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500/30 text-base resize-none"
            ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:big_description].value) %></textarea>
            <.error :for={msg <- Enum.map(@form[:big_description].errors || [], &translate_error(&1))}>
              {msg}
            </.error>
          </div>

          <%!-- Category & Privacy Row --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label for={@form[:group_id].id} class="block text-sm font-bold text-slate-700 mb-2">
                Category <span class="text-red-400">*</span>
              </label>
              <select
                name={@form[:group_id].name}
                id={@form[:group_id].id}
                required
                class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
              >
                <option value="">Select a category</option>
                {Phoenix.HTML.Form.options_for_select(
                  Enum.map(@goal_groups, &{&1.name, &1.id}),
                  @form[:group_id].value
                )}
              </select>
              <.error :for={msg <- Enum.map(@form[:group_id].errors || [], &translate_error(&1))}>
                {msg}
              </.error>
            </div>

            <div>
              <label for={@form[:privacy].id} class="block text-sm font-bold text-slate-700 mb-2">
                Privacy
              </label>
              <select
                name={@form[:privacy].name}
                id={@form[:privacy].id}
                class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
              >
                {Phoenix.HTML.Form.options_for_select(
                  [
                    {"Public - Anyone can see", :public},
                    {"Friends Only - Only friends", :friends},
                    {"Private - Only you", :private}
                  ],
                  @form[:privacy].value || :public
                )}
              </select>
              <.error :for={msg <- Enum.map(@form[:privacy].errors || [], &translate_error(&1))}>
                {msg}
              </.error>
            </div>
          </div>

          <%!-- Date & Progress Row --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label for={@form[:target_date].id} class="block text-sm font-bold text-slate-700 mb-2">
                Target Date <span class="text-slate-400 font-normal">(Optional)</span>
              </label>
              <input
                type="datetime-local"
                name={@form[:target_date].name}
                id={@form[:target_date].id}
                value={Phoenix.HTML.Form.normalize_value("datetime-local", @form[:target_date].value)}
                class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
              />
              <.error :for={msg <- Enum.map(@form[:target_date].errors || [], &translate_error(&1))}>
                {msg}
              </.error>
            </div>

            <div>
              <label for={@form[:progress].id} class="block text-sm font-bold text-slate-700 mb-2">
                Progress %
              </label>
              <input
                type="number"
                name={@form[:progress].name}
                id={@form[:progress].id}
                value={Phoenix.HTML.Form.normalize_value("number", @form[:progress].value || 0)}
                min="0"
                max="100"
                placeholder="0"
                class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
              />
              <.error :for={msg <- Enum.map(@form[:progress].errors || [], &translate_error(&1))}>
                {msg}
              </.error>
            </div>
          </div>

          <%!-- Image URL --%>
          <div>
            <label for={@form[:image_path].id} class="block text-sm font-bold text-slate-700 mb-2">
              Image URL <span class="text-slate-400 font-normal">(Optional)</span>
            </label>
            <input
              type="text"
              name={@form[:image_path].name}
              id={@form[:image_path].id}
              value={Phoenix.HTML.Form.normalize_value("text", @form[:image_path].value)}
              placeholder="https://example.com/image.jpg"
              class="w-full bg-slate-50 border-0 rounded-xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500/30 text-base font-medium"
            />
            <.error :for={msg <- Enum.map(@form[:image_path].errors || [], &translate_error(&1))}>
              {msg}
            </.error>
          </div>
        </div>

        <:actions>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-8 py-4 rounded-2xl font-bold text-base hover:scale-[1.02] transition-transform shadow-lg mt-8"
          >
            {if @action == :new, do: "Create Goal", else: "Update Goal"}
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
