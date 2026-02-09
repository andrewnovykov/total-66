defmodule HeadsUpWeb.ChallengeLive.New do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges
  alias HeadsUp.Challenges.Challenge

  @weekdays [
    {"Mon", "monday"},
    {"Tue", "tuesday"},
    {"Wed", "wednesday"},
    {"Thu", "thursday"},
    {"Fri", "friday"},
    {"Sat", "saturday"},
    {"Sun", "sunday"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if is_nil(current_user) do
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to create a challenge")
       |> push_navigate(to: ~p"/users/log_in")}
    else
      categories = Challenges.list_active_categories()
      changeset = Challenges.change_challenge(%Challenge{})

      # Admin default to "predefined" (official), users default to "custom" (community)
      default_type = if current_user.role in [:admin, "admin"], do: "predefined", else: "custom"

      socket =
        socket
        |> assign(:categories, categories)
        |> assign(:changeset, changeset)
        |> assign(:page_title, "Create Challenge")
        |> assign(:challenge_type, default_type)
        |> assign(:tasks, [%{id: 1, title: "", schedule_type: "daily", schedule_weekdays: []}])
        |> assign(:next_task_id, 2)
        |> assign(:phases, [
          %{
            id: 1,
            title: "",
            start_day: 1,
            end_day: nil,
            steps: [%{id: 1, title: "", schedule_type: "daily", schedule_weekdays: []}]
          }
        ])
        |> assign(:next_phase_id, 2)
        |> assign(:next_step_id, 2)
        |> assign(:weekdays, @weekdays)
        |> assign(:task_error, nil)
        |> assign(:phase_error, nil)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"challenge" => challenge_params}, socket) do
    changeset =
      %Challenge{}
      |> Challenges.change_challenge(challenge_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("change_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :challenge_type, type)}
  end

  @impl true
  def handle_event("set_duration", %{"days" => days}, socket) do
    days = String.to_integer(days)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:duration_days, days)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  # ============== TASK EVENTS (for Community challenges) ==============

  @impl true
  def handle_event("add_task", _params, socket) do
    new_task = %{
      id: socket.assigns.next_task_id,
      title: "",
      schedule_type: "daily",
      schedule_weekdays: []
    }

    tasks = socket.assigns.tasks ++ [new_task]

    {:noreply,
     socket
     |> assign(:tasks, tasks)
     |> assign(:next_task_id, socket.assigns.next_task_id + 1)
     |> assign(:task_error, nil)}
  end

  @impl true
  def handle_event("remove_task", %{"id" => id}, socket) do
    if length(socket.assigns.tasks) > 1 do
      tasks = Enum.reject(socket.assigns.tasks, &(&1.id == String.to_integer(id)))
      {:noreply, assign(socket, :tasks, tasks)}
    else
      {:noreply, put_flash(socket, :error, "You must have at least one task")}
    end
  end

  @impl true
  def handle_event("update_task_title", %{"id" => id, "value" => value}, socket) do
    id = String.to_integer(id)

    tasks =
      Enum.map(socket.assigns.tasks, fn task ->
        if task.id == id, do: %{task | title: value}, else: task
      end)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  @impl true
  def handle_event("update_task_schedule", %{"id" => id, "schedule" => schedule}, socket) do
    id = String.to_integer(id)

    tasks =
      Enum.map(socket.assigns.tasks, fn task ->
        if task.id == id, do: %{task | schedule_type: schedule}, else: task
      end)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  @impl true
  def handle_event("toggle_weekday", %{"task-id" => task_id, "day" => day}, socket) do
    task_id = String.to_integer(task_id)

    tasks =
      Enum.map(socket.assigns.tasks, fn task ->
        if task.id == task_id do
          weekdays = task.schedule_weekdays || []

          new_weekdays =
            if day in weekdays do
              Enum.reject(weekdays, &(&1 == day))
            else
              weekdays ++ [day]
            end

          %{task | schedule_weekdays: new_weekdays}
        else
          task
        end
      end)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  # ============== PHASE/STEP EVENTS (for Official challenges) ==============

  @impl true
  def handle_event("add_phase", _params, socket) do
    # Calculate next start day based on previous phases
    last_phase = List.last(socket.assigns.phases)
    next_start = if last_phase && last_phase.end_day, do: last_phase.end_day + 1, else: 1

    new_phase = %{
      id: socket.assigns.next_phase_id,
      title: "",
      start_day: next_start,
      end_day: nil,
      steps: [
        %{
          id: socket.assigns.next_step_id,
          title: "",
          schedule_type: "daily",
          schedule_weekdays: []
        }
      ]
    }

    phases = socket.assigns.phases ++ [new_phase]

    {:noreply,
     socket
     |> assign(:phases, phases)
     |> assign(:next_phase_id, socket.assigns.next_phase_id + 1)
     |> assign(:next_step_id, socket.assigns.next_step_id + 1)
     |> assign(:phase_error, nil)}
  end

  @impl true
  def handle_event("remove_phase", %{"id" => id}, socket) do
    if length(socket.assigns.phases) > 1 do
      phases = Enum.reject(socket.assigns.phases, &(&1.id == String.to_integer(id)))
      {:noreply, assign(socket, :phases, phases)}
    else
      {:noreply, put_flash(socket, :error, "You must have at least one phase")}
    end
  end

  @impl true
  def handle_event("update_phase_title", %{"id" => id, "value" => value}, socket) do
    id = String.to_integer(id)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == id, do: %{phase | title: value}, else: phase
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event("update_phase_start_day", %{"id" => id, "value" => value}, socket) do
    id = String.to_integer(id)
    day = if value == "", do: nil, else: String.to_integer(value)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == id, do: %{phase | start_day: day}, else: phase
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event("update_phase_end_day", %{"id" => id, "value" => value}, socket) do
    id = String.to_integer(id)
    day = if value == "", do: nil, else: String.to_integer(value)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == id, do: %{phase | end_day: day}, else: phase
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event("add_step", %{"phase-id" => phase_id}, socket) do
    phase_id = String.to_integer(phase_id)

    new_step = %{
      id: socket.assigns.next_step_id,
      title: "",
      schedule_type: "daily",
      schedule_weekdays: []
    }

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == phase_id do
          %{phase | steps: phase.steps ++ [new_step]}
        else
          phase
        end
      end)

    {:noreply,
     socket
     |> assign(:phases, phases)
     |> assign(:next_step_id, socket.assigns.next_step_id + 1)}
  end

  @impl true
  def handle_event("remove_step", %{"phase-id" => phase_id, "step-id" => step_id}, socket) do
    phase_id = String.to_integer(phase_id)
    step_id = String.to_integer(step_id)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == phase_id && length(phase.steps) > 1 do
          %{phase | steps: Enum.reject(phase.steps, &(&1.id == step_id))}
        else
          phase
        end
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event(
        "update_step_title",
        %{"phase-id" => phase_id, "step-id" => step_id, "value" => value},
        socket
      ) do
    phase_id = String.to_integer(phase_id)
    step_id = String.to_integer(step_id)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == phase_id do
          steps =
            Enum.map(phase.steps, fn step ->
              if step.id == step_id, do: %{step | title: value}, else: step
            end)

          %{phase | steps: steps}
        else
          phase
        end
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event(
        "update_step_schedule",
        %{"phase-id" => phase_id, "step-id" => step_id, "schedule" => schedule},
        socket
      ) do
    phase_id = String.to_integer(phase_id)
    step_id = String.to_integer(step_id)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == phase_id do
          steps =
            Enum.map(phase.steps, fn step ->
              if step.id == step_id, do: %{step | schedule_type: schedule}, else: step
            end)

          %{phase | steps: steps}
        else
          phase
        end
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  @impl true
  def handle_event(
        "toggle_step_weekday",
        %{"phase-id" => phase_id, "step-id" => step_id, "day" => day},
        socket
      ) do
    phase_id = String.to_integer(phase_id)
    step_id = String.to_integer(step_id)

    phases =
      Enum.map(socket.assigns.phases, fn phase ->
        if phase.id == phase_id do
          steps =
            Enum.map(phase.steps, fn step ->
              if step.id == step_id do
                weekdays = step.schedule_weekdays || []

                new_weekdays =
                  if day in weekdays do
                    Enum.reject(weekdays, &(&1 == day))
                  else
                    weekdays ++ [day]
                  end

                %{step | schedule_weekdays: new_weekdays}
              else
                step
              end
            end)

          %{phase | steps: steps}
        else
          phase
        end
      end)

    {:noreply, assign(socket, :phases, phases)}
  end

  # ============== SAVE ==============

  @impl true
  def handle_event("save", %{"challenge" => challenge_params}, socket) do
    current_user = socket.assigns.current_user
    is_admin = current_user.role in [:admin, "admin"]

    # Set type based on selection
    type =
      cond do
        is_admin && socket.assigns.challenge_type == "predefined" -> :predefined
        is_admin && socket.assigns.challenge_type == "custom" -> :custom
        true -> :custom
      end

    # Validation is based on type - Official uses duration_days, Community uses dates

    # Validate based on type
    cond do
      type == :custom && !has_valid_tasks?(socket.assigns.tasks) ->
        {:noreply,
         socket
         |> assign(:task_error, "You must add at least one task with a title")
         |> put_flash(:error, "Please add at least one task")}

      type == :predefined && !has_valid_phases?(socket.assigns.phases) ->
        {:noreply,
         socket
         |> assign(:phase_error, "You must add at least one phase with a title and one step")
         |> put_flash(:error, "Please add at least one phase with steps")}

      type == :predefined &&
          !phases_within_duration?(socket.assigns.phases, challenge_params["duration_days"]) ->
        {:noreply,
         socket
         |> assign(:phase_error, "Phase end day cannot exceed the challenge duration")
         |> put_flash(:error, "Phase days must be within the challenge duration")}

      true ->
        do_create_challenge(socket, challenge_params, type, current_user)
    end
  end

  defp has_valid_tasks?(tasks) do
    Enum.any?(tasks, &(&1.title != ""))
  end

  defp has_valid_phases?(phases) do
    Enum.any?(phases, fn phase ->
      phase.title != "" && Enum.any?(phase.steps, &(&1.title != ""))
    end)
  end

  defp phases_within_duration?(_phases, nil), do: true
  defp phases_within_duration?(_phases, ""), do: true

  defp phases_within_duration?(phases, duration_days) when is_binary(duration_days) do
    case Integer.parse(duration_days) do
      {days, _} -> phases_within_duration?(phases, days)
      :error -> true
    end
  end

  defp phases_within_duration?(phases, duration_days) when is_integer(duration_days) do
    Enum.all?(phases, fn phase ->
      phase_end = phase[:end_day]
      is_nil(phase_end) || phase_end <= duration_days
    end)
  end

  defp do_create_challenge(socket, challenge_params, type, current_user) do
    # Calculate end_date from start_date + duration_days for personal challenges
    challenge_params =
      challenge_params
      |> Map.put("type", type)
      |> maybe_calculate_end_date()
      |> normalize_challenge_params()

    case Challenges.create_challenge(challenge_params, current_user) do
      {:ok, challenge} ->
        # Create tasks or phases/steps based on type
        if type == :custom do
          create_tasks(challenge.id, socket.assigns.tasks, current_user.id)
        else
          create_phases_and_steps(challenge.id, socket.assigns.phases, current_user.id)
        end

        # Auto-join creator as participant for personal challenges (not templates)
        unless challenge.is_template do
          Challenges.join_challenge(challenge.id, current_user.id,
            start_date: challenge.start_date || Date.utc_today()
          )
        end

        {:noreply,
         socket
         |> put_flash(:info, "Challenge created successfully!")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}")}

      {:error, :unauthorized, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, :invalid_attrs, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @challenge_param_keys %{
    "title" => :title,
    "description" => :description,
    "type" => :type,
    "visibility" => :visibility,
    "status" => :status,
    "image_path" => :image_path,
    "start_date" => :start_date,
    "end_date" => :end_date,
    "duration_days" => :duration_days,
    "category_id" => :category_id,
    "template_id" => :template_id,
    "is_template" => :is_template,
    "failure_reason" => :failure_reason,
    "failed_at" => :failed_at
  }

  defp normalize_challenge_params(params) do
    Enum.reduce(params, %{}, fn
      {key, value}, acc when is_atom(key) ->
        Map.put(acc, key, value)

      {key, value}, acc when is_binary(key) ->
        case Map.fetch(@challenge_param_keys, key) do
          {:ok, atom_key} -> Map.put(acc, atom_key, value)
          :error -> acc
        end
    end)
  end

  defp create_tasks(challenge_id, tasks, user_id) do
    tasks
    |> Enum.filter(&(&1.title != ""))
    |> Enum.each(fn task ->
      Challenges.create_task(
        %{
          challenge_id: challenge_id,
          title: task.title,
          schedule_type: String.to_atom(task.schedule_type),
          schedule_weekdays: task[:schedule_weekdays] || []
        },
        user_id
      )
    end)
  end

  defp create_phases_and_steps(challenge_id, phases, user_id) do
    phases
    |> Enum.filter(&(&1.title != ""))
    |> Enum.with_index()
    |> Enum.each(fn {phase, phase_index} ->
      {:ok, created_phase} =
        Challenges.create_phase(
          %{
            challenge_id: challenge_id,
            title: phase.title,
            order_index: phase_index,
            start_day: phase[:start_day],
            end_day: phase[:end_day]
          },
          user_id
        )

      phase.steps
      |> Enum.filter(&(&1.title != ""))
      |> Enum.with_index()
      |> Enum.each(fn {step, step_index} ->
        Challenges.create_step(
          %{
            phase_id: created_phase.id,
            title: step.title,
            order_index: step_index,
            schedule_type: String.to_atom(step.schedule_type),
            schedule_weekdays: step[:schedule_weekdays] || []
          },
          user_id
        )
      end)
    end)
  end

  defp maybe_calculate_end_date(params) do
    start_date_str = Map.get(params, "start_date")
    duration_str = Map.get(params, "duration_days")

    with true <- is_binary(start_date_str) and start_date_str != "",
         {:ok, start_date} <- Date.from_iso8601(start_date_str),
         true <- is_binary(duration_str) and duration_str != "",
         {duration, _} <- Integer.parse(duration_str) do
      end_date = Date.add(start_date, duration)
      Map.put(params, "end_date", Date.to_iso8601(end_date))
    else
      _ -> params
    end
  end

  defp format_date(nil), do: ""
  defp format_date(%Date{} = date), do: Date.to_iso8601(date)
  defp format_date(date) when is_binary(date), do: date

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
              navigate={~p"/challenges"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Challenges
            </.link>

            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              New Challenge
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Create a Challenge
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Design a structured challenge to help you and others build better habits and achieve goals.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-trophy" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Form Card --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg}>
          <h2 class="text-2xl font-extrabold text-slate-900 mb-2">Challenge Details</h2>
          <p class="text-slate-500 mb-8">Fill in the details below to create your challenge.</p>

          <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-8">
            <%!-- Challenge Type indicator (admin only creates Official) --%>
            <%= if @current_user.role in [:admin, "admin"] do %>
              <div class="bg-indigo-50 rounded-2xl p-5 flex items-start gap-4">
                <div class="w-10 h-10 bg-indigo-100 rounded-xl flex items-center justify-center flex-shrink-0">
                  <.icon name="hero-shield-check" class="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <p class="font-bold text-indigo-900 text-sm">Official Challenge</p>
                  <p class="text-sm text-indigo-700 mt-1">
                    As an admin, you create Official challenges with structured phases and steps.
                  </p>
                </div>
              </div>
            <% end %>

            <%!-- Title --%>
            <div>
              <label for="challenge_title" class="block text-sm font-bold text-slate-700 mb-2">
                Title <span class="text-red-400">*</span>
              </label>
              <input
                type="text"
                id="challenge_title"
                name="challenge[title]"
                value={@changeset.changes[:title] || ""}
                class={[
                  "w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors",
                  @changeset.errors[:title] && "ring-2 ring-red-400"
                ]}
                placeholder="Enter challenge title"
                required
              />
              <%= if @changeset.errors[:title] do %>
                <p class="text-red-500 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:title], 0)}
                </p>
              <% end %>
            </div>

            <%!-- Description --%>
            <div>
              <label for="challenge_description" class="block text-sm font-bold text-slate-700 mb-2">
                Description
              </label>
              <textarea
                id="challenge_description"
                name="challenge[description]"
                rows="4"
                class="w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
                placeholder="Describe what this challenge is about..."
              >{@changeset.changes[:description] || ""}</textarea>
            </div>

            <%!-- Category --%>
            <div>
              <label for="challenge_category_id" class="block text-sm font-bold text-slate-700 mb-2">
                Category <span class="text-red-400">*</span>
              </label>
              <select
                id="challenge_category_id"
                name="challenge[category_id]"
                class={[
                  "w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors",
                  @changeset.errors[:category_id] && "ring-2 ring-red-400"
                ]}
                required
              >
                <option value="">Select a category</option>
                <%= for category <- @categories do %>
                  <option
                    value={category.id}
                    selected={to_string(category.id) == to_string(@changeset.changes[:category_id])}
                  >
                    {category.name}
                  </option>
                <% end %>
              </select>
              <%= if @changeset.errors[:category_id] do %>
                <p class="text-red-500 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:category_id], 0)}
                </p>
              <% end %>
              <%= if Enum.empty?(@categories) do %>
                <p class="text-amber-600 text-sm font-medium mt-2">
                  No categories available. Please create categories first in Admin > Challenge Categories.
                </p>
              <% end %>
            </div>

            <%!-- Visibility --%>
            <div>
              <label for="challenge_visibility" class="block text-sm font-bold text-slate-700 mb-2">
                Visibility
              </label>
              <select
                id="challenge_visibility"
                name="challenge[visibility]"
                class="w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
              >
                <option
                  value="public"
                  selected={
                    to_string(@changeset.changes[:visibility] || :public) in ["public", ":public"]
                  }
                >
                  Public - Anyone can see and join
                </option>
                <option
                  value="friends"
                  selected={to_string(@changeset.changes[:visibility]) in ["friends", ":friends"]}
                >
                  Friends Only - Only friends can see and join
                </option>
                <option
                  value="private"
                  selected={to_string(@changeset.changes[:visibility]) in ["private", ":private"]}
                >
                  Private - Only you can see
                </option>
              </select>
            </div>

            <%!-- Duration (same for both Official and Community) --%>
            <div>
              <label class="block text-sm font-bold text-slate-700 mb-3">
                Duration (Days) <span class="text-red-400">*</span>
              </label>
              <div class="flex flex-wrap gap-3">
                <button
                  type="button"
                  phx-click="set_duration"
                  phx-value-days="30"
                  class={[
                    "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                    if(@changeset.changes[:duration_days] == 30,
                      do: "bg-slate-900 text-white",
                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                    )
                  ]}
                >
                  30 Days
                </button>
                <button
                  type="button"
                  phx-click="set_duration"
                  phx-value-days="50"
                  class={[
                    "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                    if(@changeset.changes[:duration_days] == 50,
                      do: "bg-slate-900 text-white",
                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                    )
                  ]}
                >
                  50 Days
                </button>
                <button
                  type="button"
                  phx-click="set_duration"
                  phx-value-days="100"
                  class={[
                    "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                    if(@changeset.changes[:duration_days] == 100,
                      do: "bg-slate-900 text-white",
                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                    )
                  ]}
                >
                  100 Days
                </button>
                <input
                  type="number"
                  id="challenge_duration_days"
                  name="challenge[duration_days]"
                  value={@changeset.changes[:duration_days] || ""}
                  min="1"
                  max="365"
                  placeholder="Custom"
                  class={[
                    "w-28 bg-slate-50 border-0 rounded-2xl px-4 py-2.5 text-slate-900 text-sm text-center focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors",
                    @changeset.errors[:duration_days] && "ring-2 ring-red-400"
                  ]}
                />
              </div>
              <p class="text-sm text-slate-400 mt-3">
                Your challenge will start today and end after this many days.
              </p>
              <%= if @changeset.errors[:duration_days] do %>
                <p class="text-red-500 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:duration_days], 0)}
                </p>
              <% end %>
            </div>

            <%!-- Start Date --%>
            <div>
              <label for="challenge_start_date" class="block text-sm font-bold text-slate-700 mb-2">
                Start Date <span class="text-red-400">*</span>
              </label>
              <input
                type="date"
                id="challenge_start_date"
                name="challenge[start_date]"
                value={
                  format_date(@changeset.changes[:start_date])
                  |> then(fn v -> if v == "", do: Date.to_iso8601(Date.utc_today()), else: v end)
                }
                min={Date.to_iso8601(Date.utc_today())}
                class={[
                  "w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-900 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors",
                  @changeset.errors[:start_date] && "ring-2 ring-red-400"
                ]}
                required
              />
              <%= if @changeset.errors[:start_date] do %>
                <p class="text-red-500 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:start_date], 0)}
                </p>
              <% end %>
              <%= if @changeset.changes[:duration_days] && @changeset.changes[:start_date] do %>
                <p class="text-sm text-slate-500 mt-2">
                  Ends on:
                  <strong class="text-slate-700">
                    {Calendar.strftime(
                      Date.add(@changeset.changes[:start_date], @changeset.changes[:duration_days]),
                      "%B %d, %Y"
                    )}
                  </strong>
                </p>
              <% end %>
            </div>

            <%!-- PHASES & STEPS (Official/Predefined challenges) --%>
            <%= if @challenge_type == "predefined" do %>
              <div class="pt-4">
                <div class="flex justify-between items-center mb-6">
                  <div>
                    <h3 class="text-xl font-extrabold text-slate-900">
                      Phases & Steps <span class="text-red-400">*</span>
                    </h3>
                    <p class="text-sm text-slate-400 mt-1">
                      Add phases with steps that participants will complete
                    </p>
                  </div>
                  <button
                    type="button"
                    phx-click="add_phase"
                    class="inline-flex items-center gap-2 bg-indigo-50 text-indigo-600 px-4 py-2 rounded-xl text-sm font-bold hover:bg-indigo-100 transition-colors"
                  >
                    <.icon name="hero-plus" class="w-4 h-4" /> Add Phase
                  </button>
                </div>

                <%= if @phase_error do %>
                  <p class="text-red-500 text-sm font-medium mb-4">{@phase_error}</p>
                <% end %>

                <div class="space-y-6">
                  <%= for {phase, phase_idx} <- Enum.with_index(@phases) do %>
                    <div class="bg-indigo-50/50 rounded-2xl p-6">
                      <div class="flex gap-4 items-center mb-4">
                        <span class="bg-indigo-600 text-white text-xs font-bold px-3 py-1.5 rounded-full">
                          Phase {phase_idx + 1}
                        </span>
                        <input
                          type="text"
                          value={phase.title}
                          phx-blur="update_phase_title"
                          phx-value-id={phase.id}
                          placeholder="Phase title (e.g., 'Week 1 - Foundation')"
                          class="flex-1 bg-white border-0 rounded-xl px-4 py-3 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-indigo-500 transition-colors text-sm font-medium"
                        />
                        <%= if length(@phases) > 1 do %>
                          <button
                            type="button"
                            phx-click="remove_phase"
                            phx-value-id={phase.id}
                            class="text-red-400 hover:text-red-600 p-2 rounded-xl hover:bg-red-50 transition-colors"
                            title="Remove phase"
                          >
                            <.icon name="hero-trash" class="w-5 h-5" />
                          </button>
                        <% end %>
                      </div>

                      <%!-- Phase Day Range --%>
                      <div class="flex flex-wrap gap-3 mb-5 items-center">
                        <div class="flex items-center gap-2">
                          <span class="text-xs font-bold text-slate-500">Day</span>
                          <input
                            type="number"
                            value={phase.start_day || ""}
                            phx-blur="update_phase_start_day"
                            phx-value-id={phase.id}
                            min="1"
                            placeholder="1"
                            class="w-20 bg-white border-0 rounded-xl px-3 py-2.5 text-slate-900 text-sm text-center focus:ring-2 focus:ring-indigo-500 transition-colors"
                          />
                        </div>
                        <span class="text-slate-400 font-medium">to</span>
                        <div class="flex items-center gap-2">
                          <span class="text-xs font-bold text-slate-500">Day</span>
                          <input
                            type="number"
                            value={phase.end_day || ""}
                            phx-blur="update_phase_end_day"
                            phx-value-id={phase.id}
                            min="1"
                            placeholder="7"
                            class="w-20 bg-white border-0 rounded-xl px-3 py-2.5 text-slate-900 text-sm text-center focus:ring-2 focus:ring-indigo-500 transition-colors"
                          />
                        </div>
                        <span class="text-xs text-slate-400 ml-1">(e.g., Days 1-7, 8-14)</span>
                      </div>

                      <%!-- Steps within this phase --%>
                      <div class="ml-2 space-y-3">
                        <div class="flex justify-between items-center mb-2">
                          <span class="text-sm font-bold text-indigo-700">Steps</span>
                          <button
                            type="button"
                            phx-click="add_step"
                            phx-value-phase-id={phase.id}
                            class="inline-flex items-center gap-1 text-indigo-600 hover:text-indigo-800 text-xs font-bold"
                          >
                            <.icon name="hero-plus" class="w-3 h-3" /> Add Step
                          </button>
                        </div>
                        <%= for {step, step_idx} <- Enum.with_index(phase.steps) do %>
                          <div class="bg-white rounded-2xl p-4 soft-shadow border border-slate-50">
                            <div class="flex gap-3 items-center">
                              <span class="text-slate-400 text-sm font-bold w-6">
                                {step_idx + 1}.
                              </span>
                              <input
                                type="text"
                                value={step.title}
                                phx-blur="update_step_title"
                                phx-value-phase-id={phase.id}
                                phx-value-step-id={step.id}
                                placeholder="Step title (e.g., 'Complete introduction')"
                                class="flex-1 bg-slate-50 border-0 rounded-xl px-4 py-2.5 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors text-sm"
                              />
                              <%= if length(phase.steps) > 1 do %>
                                <button
                                  type="button"
                                  phx-click="remove_step"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  class="text-red-400 hover:text-red-600 p-1.5 rounded-lg hover:bg-red-50 transition-colors"
                                  title="Remove step"
                                >
                                  <.icon name="hero-x-mark" class="w-4 h-4" />
                                </button>
                              <% end %>
                            </div>
                            <%!-- Schedule type pills for step --%>
                            <div class="mt-3 ml-9">
                              <p class="text-xs font-bold text-slate-500 mb-2">Schedule</p>
                              <div class="flex flex-wrap gap-1.5">
                                <button
                                  type="button"
                                  phx-click="update_step_schedule"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  phx-value-schedule="daily"
                                  class={[
                                    "px-3 py-1 rounded-full text-xs font-bold transition-all",
                                    if(step.schedule_type in ["daily", :daily],
                                      do: "bg-slate-900 text-white",
                                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                    )
                                  ]}
                                >
                                  Daily
                                </button>
                                <button
                                  type="button"
                                  phx-click="update_step_schedule"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  phx-value-schedule="twice_week"
                                  class={[
                                    "px-3 py-1 rounded-full text-xs font-bold transition-all",
                                    if(step.schedule_type in ["twice_week", :twice_week],
                                      do: "bg-slate-900 text-white",
                                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                    )
                                  ]}
                                >
                                  2x/week
                                </button>
                                <button
                                  type="button"
                                  phx-click="update_step_schedule"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  phx-value-schedule="every_other_day"
                                  class={[
                                    "px-3 py-1 rounded-full text-xs font-bold transition-all",
                                    if(step.schedule_type in ["every_other_day", :every_other_day],
                                      do: "bg-slate-900 text-white",
                                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                    )
                                  ]}
                                >
                                  Alt days
                                </button>
                                <button
                                  type="button"
                                  phx-click="update_step_schedule"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  phx-value-schedule="mon_fri"
                                  class={[
                                    "px-3 py-1 rounded-full text-xs font-bold transition-all",
                                    if(step.schedule_type in ["mon_fri", :mon_fri],
                                      do: "bg-slate-900 text-white",
                                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                    )
                                  ]}
                                >
                                  Mon-Fri
                                </button>
                                <button
                                  type="button"
                                  phx-click="update_step_schedule"
                                  phx-value-phase-id={phase.id}
                                  phx-value-step-id={step.id}
                                  phx-value-schedule="custom_weekdays"
                                  class={[
                                    "px-3 py-1 rounded-full text-xs font-bold transition-all",
                                    if(step.schedule_type in ["custom_weekdays", :custom_weekdays],
                                      do: "bg-slate-900 text-white",
                                      else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                    )
                                  ]}
                                >
                                  Custom
                                </button>
                              </div>
                            </div>
                            <%!-- Custom weekdays for step --%>
                            <%= if step.schedule_type in ["custom_weekdays", :custom_weekdays] do %>
                              <div class="mt-3 pt-3 border-t border-slate-100 ml-9">
                                <p class="text-xs font-bold text-slate-500 mb-2">Select days</p>
                                <div class="flex flex-wrap gap-1.5">
                                  <%= for {label, value} <- @weekdays do %>
                                    <button
                                      type="button"
                                      phx-click="toggle_step_weekday"
                                      phx-value-phase-id={phase.id}
                                      phx-value-step-id={step.id}
                                      phx-value-day={value}
                                      class={[
                                        "px-3 py-1.5 rounded-full text-xs font-bold transition-all",
                                        if(value in (step.schedule_weekdays || []),
                                          do: "bg-indigo-600 text-white",
                                          else:
                                            "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                        )
                                      ]}
                                    >
                                      {label}
                                    </button>
                                  <% end %>
                                </div>
                              </div>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%!-- TASKS (Community/Custom challenges) --%>
            <%= if @challenge_type == "custom" do %>
              <div class="pt-4">
                <div class="flex justify-between items-center mb-6">
                  <div>
                    <h3 class="text-xl font-extrabold text-slate-900">
                      Tasks <span class="text-red-400">*</span>
                    </h3>
                    <p class="text-sm text-slate-400 mt-1">Add scheduled tasks for this challenge</p>
                  </div>
                  <button
                    type="button"
                    phx-click="add_task"
                    class="inline-flex items-center gap-2 bg-blue-50 text-blue-600 px-4 py-2 rounded-xl text-sm font-bold hover:bg-blue-100 transition-colors"
                  >
                    <.icon name="hero-plus" class="w-4 h-4" /> Add Task
                  </button>
                </div>

                <%= if @task_error do %>
                  <p class="text-red-500 text-sm font-medium mb-4">{@task_error}</p>
                <% end %>

                <div class="space-y-4">
                  <%= for task <- @tasks do %>
                    <div class="bg-slate-50 rounded-2xl p-5">
                      <div class="flex gap-4 items-start">
                        <div class="flex-1">
                          <input
                            type="text"
                            value={task.title}
                            phx-blur="update_task_title"
                            phx-value-id={task.id}
                            placeholder="Task title (e.g., 'Morning workout')"
                            class="w-full bg-white border-0 rounded-xl px-4 py-3 text-slate-900 placeholder-slate-400 focus:ring-2 focus:ring-blue-500 transition-colors font-medium"
                          />
                        </div>
                        <%= if length(@tasks) > 1 do %>
                          <button
                            type="button"
                            phx-click="remove_task"
                            phx-value-id={task.id}
                            class="text-red-400 hover:text-red-600 p-2 rounded-xl hover:bg-red-50 transition-colors"
                            title="Remove task"
                          >
                            <.icon name="hero-trash" class="w-5 h-5" />
                          </button>
                        <% end %>
                      </div>

                      <%!-- Schedule type pills --%>
                      <div class="mt-4">
                        <p class="text-xs font-bold text-slate-500 mb-2">Schedule</p>
                        <div class="flex flex-wrap gap-2">
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule="daily"
                            class={[
                              "px-4 py-1.5 rounded-full text-xs font-bold transition-all",
                              if(task.schedule_type in ["daily", :daily],
                                do: "bg-slate-900 text-white",
                                else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                              )
                            ]}
                          >
                            Daily
                          </button>
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule="twice_week"
                            class={[
                              "px-4 py-1.5 rounded-full text-xs font-bold transition-all",
                              if(task.schedule_type in ["twice_week", :twice_week],
                                do: "bg-slate-900 text-white",
                                else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                              )
                            ]}
                          >
                            Twice/week
                          </button>
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule="every_other_day"
                            class={[
                              "px-4 py-1.5 rounded-full text-xs font-bold transition-all",
                              if(task.schedule_type in ["every_other_day", :every_other_day],
                                do: "bg-slate-900 text-white",
                                else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                              )
                            ]}
                          >
                            Every other day
                          </button>
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule="mon_fri"
                            class={[
                              "px-4 py-1.5 rounded-full text-xs font-bold transition-all",
                              if(task.schedule_type in ["mon_fri", :mon_fri],
                                do: "bg-slate-900 text-white",
                                else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                              )
                            ]}
                          >
                            Mon-Fri
                          </button>
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule="custom_weekdays"
                            class={[
                              "px-4 py-1.5 rounded-full text-xs font-bold transition-all",
                              if(task.schedule_type in ["custom_weekdays", :custom_weekdays],
                                do: "bg-slate-900 text-white",
                                else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                              )
                            ]}
                          >
                            Custom days
                          </button>
                        </div>
                      </div>

                      <%!-- Custom weekdays selection --%>
                      <%= if task.schedule_type in ["custom_weekdays", :custom_weekdays] do %>
                        <div class="mt-4 pt-4 border-t border-slate-200">
                          <p class="text-xs font-bold text-slate-500 mb-2">
                            Select days for this task
                          </p>
                          <div class="flex flex-wrap gap-2">
                            <%= for {label, value} <- @weekdays do %>
                              <button
                                type="button"
                                phx-click="toggle_weekday"
                                phx-value-task-id={task.id}
                                phx-value-day={value}
                                class={[
                                  "px-4 py-2 rounded-full text-sm font-bold transition-all",
                                  if(value in (task.schedule_weekdays || []),
                                    do: "bg-blue-600 text-white",
                                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                                  )
                                ]}
                              >
                                {label}
                              </button>
                            <% end %>
                          </div>
                          <%= if Enum.empty?(task.schedule_weekdays || []) do %>
                            <p class="text-amber-500 text-xs font-medium mt-2">
                              Please select at least one day
                            </p>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%!-- Submit --%>
            <div class="pt-4">
              <button
                type="submit"
                class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white font-bold py-4 px-6 rounded-2xl disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg shadow-blue-500/20 text-base"
                disabled={Enum.empty?(@categories)}
              >
                Create Challenge
              </button>
            </div>
          </.form>
        </HeadsUpWeb.Components.UI.Card.card>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Tips --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Tips for Challenges</h3>
          <div class="space-y-4">
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-light-bulb" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Start Small</p>
                <p class="text-slate-500 text-sm mt-1">
                  Begin with achievable daily tasks to build momentum.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-calendar-days" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Choose a Duration</p>
                <p class="text-slate-500 text-sm mt-1">
                  30-day challenges are popular and keep participants engaged.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-user-group" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Make it Public</p>
                <p class="text-slate-500 text-sm mt-1">
                  Public challenges attract more participants and build community.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-clipboard-document-check" class="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Clear Tasks</p>
                <p class="text-slate-500 text-sm mt-1">
                  Well-defined tasks help participants know exactly what to do each day.
                </p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
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
            <.link
              navigate={~p"/challenges/my"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Challenges</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
    </div>
    """
  end
end
