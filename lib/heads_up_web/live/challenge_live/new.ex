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
      changeset = Challenges.change_challenge(%Challenge{})

      # Admin defaults to "official", users default to "community"
      default_type = if current_user.role in [:admin, "admin"], do: "official", else: "community"

      socket =
        socket
        |> assign(:changeset, changeset)
        |> assign(:page_title, "Create Challenge")
        |> assign(:challenge_type, default_type)
        |> assign(:tasks, [%{id: 1, title: "", schedule_type: "daily", schedule_weekdays: [], task_type: "mandatory"}])
        |> assign(:next_task_id, 2)
        |> assign(:weekdays, @weekdays)
        |> assign(:task_error, nil)

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

  # ============== TASK EVENTS ==============

  @impl true
  def handle_event("add_task", _params, socket) do
    new_task = %{
      id: socket.assigns.next_task_id,
      title: "",
      schedule_type: "daily",
      schedule_weekdays: [],
      task_type: "mandatory"
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
  def handle_event("update_task_type", %{"id" => id, "type" => type}, socket) do
    id = String.to_integer(id)

    tasks =
      Enum.map(socket.assigns.tasks, fn task ->
        if task.id == id, do: %{task | task_type: type}, else: task
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

  # ============== SAVE ==============

  @impl true
  def handle_event("save", %{"challenge" => challenge_params}, socket) do
    current_user = socket.assigns.current_user
    is_admin = current_user.role in [:admin, "admin"]

    # Set type based on selection
    type =
      cond do
        is_admin && socket.assigns.challenge_type == "official" -> :official
        is_admin && socket.assigns.challenge_type == "community" -> :community
        true -> :community
      end

    # Validate tasks
    if !has_valid_tasks?(socket.assigns.tasks) do
      {:noreply,
       socket
       |> assign(:task_error, "You must add at least one task with a title")
       |> put_flash(:error, "Please add at least one task")}
    else
      do_create_challenge(socket, challenge_params, type, current_user)
    end
  end

  defp has_valid_tasks?(tasks) do
    Enum.any?(tasks, &(&1.title != ""))
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
        # Create tasks for the challenge
        create_tasks(challenge.id, socket.assigns.tasks, current_user.id)

        # Auto-join creator as participant for personal challenges (not templates)
        redirect_to =
          unless challenge.is_template do
            Challenges.join_challenge(challenge.id, current_user.id,
              start_date: challenge.start_date || Date.utc_today()
            )

            ~p"/my-challenges/#{challenge.id}"
          else
            ~p"/challenges/#{challenge.id}"
          end

        {:noreply,
         socket
         |> put_flash(:info, "Challenge created successfully!")
         |> push_navigate(to: redirect_to)}

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
    |> Enum.with_index()
    |> Enum.each(fn {task, index} ->
      Challenges.create_task(
        %{
          challenge_id: challenge_id,
          title: task.title,
          schedule_type: String.to_atom(task.schedule_type),
          schedule_weekdays: task[:schedule_weekdays] || [],
          task_type: String.to_atom(task[:task_type] || "mandatory"),
          order_index: index
        },
        user_id
      )
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
    <style>
      @keyframes panelIn {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
    </style>

    <div style="animation: panelIn 0.4s ease both;">
      <div class="max-w-3xl mx-auto px-5 sm:px-8 py-8 sm:py-12">
        <%!-- Back Link --%>
        <.link
          navigate={~p"/challenges"}
          class="inline-flex items-center gap-2 text-t66-text-muted hover:text-[#f0ece6] text-sm font-medium mb-8 transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Challenges
        </.link>

        <%!-- Page Header --%>
        <div class="text-center mb-10 relative">
          <div class="text-[0.7rem] tracking-[4px] uppercase text-t66-accent font-bold mb-3">
            New Challenge
          </div>
          <h1 class="font-['Bebas_Neue'] text-[clamp(2.2rem,5vw,3.4rem)] tracking-[3px] text-[#f0ece6] leading-none mb-2">
            Create a Challenge
          </h1>
          <p class="text-t66-text-muted text-[0.95rem] max-w-lg mx-auto">
            Design your challenge. Choose duration, add tasks, and start your journey.
          </p>
        </div>

        <%!-- Form Card --%>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-6 sm:p-8">
          <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-7">
            <%!-- Admin Official Badge --%>
            <%= if @current_user.role in [:admin, "admin"] do %>
              <div class="bg-[rgba(255,77,0,0.08)] border border-[rgba(255,77,0,0.15)] rounded-xl p-4 flex items-start gap-3.5">
                <div class="w-10 h-10 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center flex-shrink-0">
                  <.icon name="hero-shield-check" class="w-5 h-5 text-t66-accent" />
                </div>
                <div>
                  <p class="font-bold text-[#f0ece6] text-sm">Official Challenge</p>
                  <p class="text-sm text-t66-text-muted mt-1">
                    As an admin, you create Official challenge templates for all users.
                  </p>
                </div>
              </div>
            <% end %>

            <%!-- Title --%>
            <div>
              <label
                for="challenge_title"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Title <span class="text-red-400">*</span>
              </label>
              <input
                type="text"
                id="challenge_title"
                name="challenge[title]"
                value={@changeset.changes[:title] || ""}
                class={[
                  "w-full bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-3.5 text-[#f0ece6] placeholder-[#5a5754] text-[0.9rem] outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)]",
                  @changeset.errors[:title] && "border-red-400/50"
                ]}
                placeholder="Enter challenge title"
                required
              />
              <%= if @changeset.errors[:title] do %>
                <p class="text-red-400 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:title], 0)}
                </p>
              <% end %>
            </div>

            <%!-- Description --%>
            <div>
              <label
                for="challenge_description"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Description
              </label>
              <textarea
                id="challenge_description"
                name="challenge[description]"
                rows="4"
                class="w-full bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-3.5 text-[#f0ece6] placeholder-[#5a5754] text-[0.9rem] outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)] resize-y min-h-[100px]"
                placeholder="Describe what this challenge is about..."
              >{@changeset.changes[:description] || ""}</textarea>
            </div>

            <%!-- Visibility --%>
            <div>
              <label
                for="challenge_visibility"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Visibility
              </label>
              <select
                id="challenge_visibility"
                name="challenge[visibility]"
                class="w-full bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-3.5 text-[#f0ece6] text-[0.9rem] outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              >
                <option
                  value="public"
                  selected={
                    to_string(@changeset.changes[:visibility] || :public) in ["public", ":public"]
                  }
                  class="bg-[#131313]"
                >
                  Public - Anyone can see and join
                </option>
                <option
                  value="friends"
                  selected={to_string(@changeset.changes[:visibility]) in ["friends", ":friends"]}
                  class="bg-[#131313]"
                >
                  Friends Only - Only friends can see and join
                </option>
                <option
                  value="private"
                  selected={to_string(@changeset.changes[:visibility]) in ["private", ":private"]}
                  class="bg-[#131313]"
                >
                  Private - Only you can see
                </option>
              </select>
            </div>

            <%!-- Duration (Days) --%>
            <div>
              <label class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-3">
                Duration (Days) <span class="text-red-400">*</span>
              </label>
              <div class="flex flex-wrap gap-3">
                <%= for {days, label} <- [{30, "30 Days"}, {50, "50 Days"}, {66, "66 Days"}, {100, "100 Days"}] do %>
                  <button
                    type="button"
                    phx-click="set_duration"
                    phx-value-days={days}
                    class={[
                      "px-5 py-2.5 rounded-xl text-sm font-bold transition-all border",
                      if(@changeset.changes[:duration_days] == days,
                        do:
                          "border-t66-accent text-t66-accent bg-[rgba(255,77,0,0.15)]",
                        else:
                          "border-white/[0.06] text-[#8a8680] bg-[#0a0a0a] hover:border-white/[0.12] hover:text-[#f0ece6]"
                      )
                    ]}
                  >
                    {label}
                  </button>
                <% end %>
                <input
                  type="number"
                  id="challenge_duration_days"
                  name="challenge[duration_days]"
                  value={@changeset.changes[:duration_days] || ""}
                  min="1"
                  max="365"
                  placeholder="Custom"
                  class={[
                    "w-28 bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-2.5 text-[#f0ece6] text-sm text-center outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)]",
                    @changeset.errors[:duration_days] && "border-red-400/50"
                  ]}
                />
              </div>
              <p class="text-sm text-t66-text-muted mt-3">
                Your challenge will start on the selected date and end after this many days.
              </p>
              <%= if @changeset.errors[:duration_days] do %>
                <p class="text-red-400 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:duration_days], 0)}
                </p>
              <% end %>
            </div>

            <%!-- Start Date --%>
            <div>
              <label
                for="challenge_start_date"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
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
                  "w-full bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-3.5 text-[#f0ece6] text-[0.9rem] outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)] [color-scheme:dark]",
                  @changeset.errors[:start_date] && "border-red-400/50"
                ]}
                required
              />
              <%= if @changeset.errors[:start_date] do %>
                <p class="text-red-400 text-sm font-medium mt-2">
                  {elem(@changeset.errors[:start_date], 0)}
                </p>
              <% end %>
              <%= if @changeset.changes[:duration_days] && @changeset.changes[:start_date] do %>
                <p class="text-sm text-t66-text-muted mt-2">
                  Ends on:
                  <strong class="text-t66-accent">
                    {Calendar.strftime(
                      Date.add(@changeset.changes[:start_date], @changeset.changes[:duration_days]),
                      "%B %d, %Y"
                    )}
                  </strong>
                </p>
              <% end %>
            </div>

            <%!-- ══════ TASKS ══════ --%>
            <div class="pt-2">
              <div class="flex justify-between items-center mb-5">
                <div>
                  <h3 class="font-['Bebas_Neue'] text-[1.4rem] tracking-[2px] text-[#f0ece6]">
                    Tasks <span class="text-red-400">*</span>
                  </h3>
                  <p class="text-sm text-t66-text-muted mt-1">
                    Add scheduled tasks for this challenge
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="add_task"
                  class="inline-flex items-center gap-2 bg-[rgba(255,77,0,0.12)] text-t66-accent px-4 py-2 rounded-xl text-sm font-bold hover:bg-[rgba(255,77,0,0.2)] transition-colors border border-[rgba(255,77,0,0.2)]"
                >
                  <.icon name="hero-plus" class="w-4 h-4" /> Add Task
                </button>
              </div>

              <%= if @task_error do %>
                <p class="text-red-400 text-sm font-medium mb-4">{@task_error}</p>
              <% end %>

              <div class="space-y-3">
                <%= for task <- @tasks do %>
                  <div class="bg-[#0a0a0a] border border-white/[0.06] rounded-xl p-4">
                    <div class="flex gap-3 items-start">
                      <div class="flex-1">
                        <input
                          type="text"
                          value={task.title}
                          phx-blur="update_task_title"
                          phx-value-id={task.id}
                          placeholder="Task title (e.g., 'Morning workout')"
                          class="w-full bg-[#0f0f0f] border border-white/[0.08] rounded-xl px-4 py-3 text-[#f0ece6] placeholder-[#5a5754] text-[0.88rem] font-medium outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
                        />
                      </div>
                      <%= if length(@tasks) > 1 do %>
                        <button
                          type="button"
                          phx-click="remove_task"
                          phx-value-id={task.id}
                          class="text-[#5a5754] hover:text-red-400 p-2 rounded-xl hover:bg-[rgba(239,68,68,0.1)] transition-colors mt-0.5"
                          title="Remove task"
                        >
                          <.icon name="hero-trash" class="w-5 h-5" />
                        </button>
                      <% end %>
                    </div>

                    <%!-- Task Type pills --%>
                    <div class="mt-3">
                      <p class="text-xs font-bold text-t66-text-muted mb-2">Type</p>
                      <div class="flex gap-2">
                        <%= for {type_label, type_value} <- [{"Mandatory", "mandatory"}, {"Optional", "optional"}] do %>
                          <button
                            type="button"
                            phx-click="update_task_type"
                            phx-value-id={task.id}
                            phx-value-type={type_value}
                            class={[
                              "px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all border",
                              if(task.task_type == type_value,
                                do:
                                  "border-t66-accent text-t66-accent bg-[rgba(255,77,0,0.15)]",
                                else:
                                  "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                              )
                            ]}
                          >
                            {type_label}
                          </button>
                        <% end %>
                      </div>
                    </div>

                    <%!-- Schedule pills --%>
                    <div class="mt-3">
                      <p class="text-xs font-bold text-t66-text-muted mb-2">Schedule</p>
                      <div class="flex flex-wrap gap-2">
                        <%= for {sched_label, sched_value} <- [{"Daily", "daily"}, {"Twice/week", "twice_week"}, {"Every other day", "every_other_day"}, {"Mon-Fri", "mon_fri"}, {"Custom days", "custom_weekdays"}] do %>
                          <button
                            type="button"
                            phx-click="update_task_schedule"
                            phx-value-id={task.id}
                            phx-value-schedule={sched_value}
                            class={[
                              "px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all border",
                              if(task.schedule_type in [sched_value, String.to_atom(sched_value)],
                                do:
                                  "border-t66-accent text-t66-accent bg-[rgba(255,77,0,0.15)]",
                                else:
                                  "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                              )
                            ]}
                          >
                            {sched_label}
                          </button>
                        <% end %>
                      </div>
                    </div>

                    <%!-- Custom weekdays --%>
                    <%= if task.schedule_type in ["custom_weekdays", :custom_weekdays] do %>
                      <div class="mt-3 pt-3 border-t border-white/[0.06]">
                        <p class="text-xs font-bold text-t66-text-muted mb-2">
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
                                "w-[30px] h-[30px] rounded-md text-[0.65rem] font-bold flex items-center justify-center transition-all border",
                                if(value in (task.schedule_weekdays || []),
                                  do:
                                    "border-t66-accent text-t66-accent bg-[rgba(255,77,0,0.15)]",
                                  else:
                                    "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12]"
                                )
                              ]}
                            >
                              {label}
                            </button>
                          <% end %>
                        </div>
                        <%= if Enum.empty?(task.schedule_weekdays || []) do %>
                          <p class="text-amber-400 text-xs font-medium mt-2">
                            Please select at least one day
                          </p>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Submit --%>
            <div class="pt-4">
              <button
                type="submit"
                class="w-full bg-t66-accent hover:bg-[#e64400] text-white font-bold py-4 px-6 rounded-xl disabled:opacity-40 disabled:cursor-not-allowed transition-all text-[0.85rem] tracking-[2px] uppercase shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] hover:-translate-y-0.5"
              >
                Create Challenge
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
