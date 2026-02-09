defmodule HeadsUpWeb.ChallengeLive.Active do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user
    challenge = Challenges.get_challenge_for_display(id)

    cond do
      is_nil(challenge) ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/challenges")}

      challenge.is_template ->
        {:ok, push_navigate(socket, to: ~p"/challenges/#{challenge.id}")}

      true ->
        participant = Challenges.get_participant(challenge.id, current_user.id)

        if is_nil(participant) do
          {:ok, push_navigate(socket, to: ~p"/challenges/#{challenge.id}")}
        else
          mount_active_challenge(socket, challenge, participant, current_user)
        end
    end
  end

  defp mount_active_challenge(socket, challenge, participant, current_user) do
    # Check auto-fail (7 missed days)
    {participant, challenge} =
      if participant.status == :active do
        case Challenges.check_and_auto_fail(participant.id) do
          {:ok, :auto_failed} ->
            {Challenges.get_participant(challenge.id, current_user.id),
             Challenges.get_challenge_for_display(challenge.id)}

          _ ->
            {participant, challenge}
        end
      else
        {participant, challenge}
      end

    progress = Challenges.get_participant_progress(participant.id)
    today_items = Challenges.get_today_items(challenge.id, participant.id)
    has_checked_in = Challenges.has_checked_in_today?(participant.id)
    feed = Challenges.get_challenge_feed(challenge.id, current_user.id)
    mood_history = Challenges.get_mood_history(participant.id)
    missed_days = Challenges.get_missed_check_in_days(participant.id)

    challenge_started =
      participant.start_date != nil &&
        Date.compare(Date.utc_today(), participant.start_date) != :lt

    total_days = calculate_challenge_duration(challenge)
    days_elapsed = if progress, do: Map.get(progress, :days_elapsed, 0), else: 0
    progress_pct = if total_days > 0, do: min(round(days_elapsed / total_days * 100), 100), else: 0

    socket =
      socket
      |> assign(:challenge, challenge)
      |> assign(:participant, participant)
      |> assign(:progress, progress)
      |> assign(:total_days, total_days)
      |> assign(:days_elapsed, days_elapsed)
      |> assign(:progress_pct, progress_pct)
      |> assign(:page_title, challenge.title)
      |> assign(:today_items, today_items)
      |> assign(:has_checked_in, has_checked_in)
      |> assign(:feed, feed)
      |> assign(:mood_history, mood_history)
      |> assign(:missed_days, missed_days)
      |> assign(:check_in_note, "")
      |> assign(:check_in_mood, nil)
      |> assign(:show_fail_modal, false)
      |> assign(:failure_reason, "")
      |> assign(:challenge_started, challenge_started)
      |> assign(:current_user_id, current_user.id)
      |> assign(:expanded_check_in_comments, MapSet.new())

    {:ok, socket}
  end

  # ============================================================================
  # Task Events
  # ============================================================================

  @impl true
  def handle_event("complete_task", %{"task-id" => task_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.complete_task(participant.id, String.to_integer(task_id)) do
      {:ok, _} ->
        {:noreply, refresh_progress(socket, challenge, participant, "Task completed!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete task.")}
    end
  end

  @impl true
  def handle_event("fail_task", %{"task-id" => task_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.fail_task(participant.id, String.to_integer(task_id)) do
      {:ok, _} ->
        {:noreply, refresh_progress(socket, challenge, participant, "Task marked as failed.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not mark task as failed.")}
    end
  end

  @impl true
  def handle_event("uncomplete_task", %{"task-id" => task_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.uncomplete_task(participant.id, String.to_integer(task_id), Date.utc_today()) do
      {:ok, _} ->
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)

        {:noreply,
         socket
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> recalc_progress()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not uncomplete task.")}
    end
  end

  # ============================================================================
  # Check-in Events
  # ============================================================================

  @impl true
  def handle_event("update_check_in_note", %{"value" => value}, socket) do
    {:noreply, assign(socket, :check_in_note, value)}
  end

  @impl true
  def handle_event("select_mood", %{"mood" => mood}, socket) do
    current = socket.assigns.check_in_mood
    new_mood = if current == mood, do: nil, else: mood
    {:noreply, assign(socket, :check_in_mood, new_mood)}
  end

  @impl true
  def handle_event("finish_day", _params, socket) do
    participant = socket.assigns.participant
    note = if socket.assigns.check_in_note == "", do: nil, else: socket.assigns.check_in_note

    case Challenges.create_daily_check_in(participant.id, %{
           note: note,
           mood: socket.assigns.check_in_mood
         }) do
      {:ok, _} ->
        refresh_after_check_in(socket, "Day completed! Great work!")

      {:error, :already_checked_in} ->
        {:noreply, put_flash(socket, :error, "You've already checked in for today.")}

      {:error, :challenge_not_active} ->
        {:noreply, put_flash(socket, :error, "Challenge is not active.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete day check-in.")}
    end
  end

  @impl true
  def handle_event("check_in_missed_day", %{"date" => date_str}, socket) do
    participant = socket.assigns.participant

    case Challenges.create_daily_check_in(participant.id, %{check_in_date: date_str}) do
      {:ok, _} ->
        refresh_after_check_in(socket, "Checked in for #{date_str}!")

      {:error, :already_checked_in} ->
        {:noreply, put_flash(socket, :error, "Already checked in for that day.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not check in for that day.")}
    end
  end

  # ============================================================================
  # Fail/Cancel Events
  # ============================================================================

  @impl true
  def handle_event("show_fail_modal", _params, socket) do
    {:noreply, assign(socket, show_fail_modal: true, failure_reason: "")}
  end

  @impl true
  def handle_event("close_fail_modal", _params, socket) do
    {:noreply, assign(socket, show_fail_modal: false, failure_reason: "")}
  end

  @impl true
  def handle_event("update_failure_reason", %{"value" => value}, socket) do
    {:noreply, assign(socket, :failure_reason, value)}
  end

  @impl true
  def handle_event("confirm_fail_challenge", _params, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge
    reason = if socket.assigns.failure_reason == "", do: nil, else: socket.assigns.failure_reason

    case Challenges.fail_challenge(challenge.id, current_user.id, reason) do
      {:ok, updated_challenge} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> assign(:challenge, Challenges.get_challenge_for_display(updated_challenge.id))
         |> assign(:participant, Challenges.get_participant(challenge.id, current_user.id))
         |> put_flash(:info, "Challenge marked as failed.")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> put_flash(:error, "Could not fail challenge.")}
    end
  end

  # ============================================================================
  # Feed Engagement Events
  # ============================================================================

  @impl true
  def handle_event("toggle_check_in_like", %{"check-in-id" => id}, socket) do
    {check_in_id, _} = Integer.parse(id)
    current_user_id = socket.assigns.current_user_id

    was_liked =
      Map.get(
        Enum.find(socket.assigns.feed, &(&1.id == check_in_id)) || %{},
        :user_liked,
        false
      )

    case Challenges.react_to_check_in(check_in_id, current_user_id, "like") do
      {:ok, _} ->
        now_liked = Challenges.user_liked_check_in?(check_in_id, current_user_id)

        delta =
          if now_liked && !was_liked, do: 1, else: if(!now_liked && was_liked, do: -1, else: 0)

        feed =
          update_check_in_in_feed(socket.assigns.feed, check_in_id, fn ci ->
            ci
            |> Map.put(:like_count, max(Map.get(ci, :like_count, 0) + delta, 0))
            |> Map.put(:user_liked, now_liked)
          end)

        {:noreply, assign(socket, :feed, feed)}

      {:error, :cannot_like_own_check_in} ->
        {:noreply, put_flash(socket, :error, "You cannot like your own check-in")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like check-in")}
    end
  end

  @impl true
  def handle_event("toggle_check_in_comments", %{"check-in-id" => id}, socket) do
    {check_in_id, _} = Integer.parse(id)
    expanded = socket.assigns.expanded_check_in_comments

    {expanded, feed} =
      if MapSet.member?(expanded, check_in_id) do
        {MapSet.delete(expanded, check_in_id), socket.assigns.feed}
      else
        comments = Challenges.list_check_in_comments(check_in_id)

        feed =
          update_check_in_in_feed(socket.assigns.feed, check_in_id, fn ci ->
            Map.put(ci, :comments, comments)
          end)

        {MapSet.put(expanded, check_in_id), feed}
      end

    {:noreply,
     socket
     |> assign(:expanded_check_in_comments, expanded)
     |> assign(:feed, feed)}
  end

  @impl true
  def handle_event("add_check_in_comment", %{"check-in-id" => id, "content" => content}, socket) do
    {check_in_id, _} = Integer.parse(id)
    trimmed = String.trim(content)

    if trimmed == "" do
      {:noreply, put_flash(socket, :error, "Comment cannot be empty")}
    else
      case Challenges.create_check_in_comment(%{
             check_in_id: check_in_id,
             user_id: socket.assigns.current_user_id,
             content: trimmed
           }) do
        {:ok, comment} ->
          feed =
            update_check_in_in_feed(socket.assigns.feed, check_in_id, fn ci ->
              ci
              |> Map.put(:comments, Map.get(ci, :comments, []) ++ [comment])
              |> Map.put(:comment_count, Map.get(ci, :comment_count, 0) + 1)
            end)

          {:noreply, assign(socket, :feed, feed)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add comment")}
      end
    end
  end

  @impl true
  def handle_event(
        "delete_check_in_comment",
        %{"comment-id" => cid, "check-in-id" => id},
        socket
      ) do
    {comment_id, _} = Integer.parse(cid)
    {check_in_id, _} = Integer.parse(id)
    comment = Challenges.get_check_in_comment!(comment_id)

    case Challenges.delete_check_in_comment(comment, socket.assigns.current_user_id) do
      {:ok, _} ->
        feed =
          update_check_in_in_feed(socket.assigns.feed, check_in_id, fn ci ->
            ci
            |> Map.put(
              :comments,
              Enum.reject(Map.get(ci, :comments, []), &(&1.id == comment_id))
            )
            |> Map.put(:comment_count, max(Map.get(ci, :comment_count, 0) - 1, 0))
          end)

        {:noreply, assign(socket, :feed, feed)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You cannot delete this comment")}
    end
  end

  # ============================================================================
  # Render
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      .mood-grid-22 { display: grid; grid-template-columns: repeat(22, 1fr); gap: 4px; }
      @media (max-width: 860px) { .mood-grid-22 { grid-template-columns: repeat(11, 1fr); } }
    </style>

    <div class="max-w-[900px] mx-auto space-y-6">
      <%!-- ═══ SECTION 1: CHALLENGE HEADER ═══ --%>
      <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-8 relative overflow-hidden">
        <%!-- Top accent gradient --%>
        <div class="absolute top-0 left-0 right-0 h-[3px] bg-gradient-to-r from-t66-accent to-[#ff8a50]">
        </div>

        <div class="flex justify-between items-start gap-4 flex-wrap mb-5">
          <div>
            <%!-- Status badge --%>
            <div class={[
              "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[0.65rem] uppercase tracking-[2px] font-bold mb-2.5",
              status_badge_class(@participant.status)
            ]}>
              <span class="text-[0.5rem]">●</span>
              {status_label(@participant.status)}
              <%= if @participant.status == :active && @challenge_started do %>
                <span>· Day {@days_elapsed}</span>
              <% end %>
            </div>
            <%!-- Title --%>
            <h1 class="font-display text-[clamp(1.8rem,3vw,2.6rem)] tracking-[3px] leading-[1.1] text-t66-text">
              {@challenge.title}
            </h1>
            <%!-- Dates --%>
            <div class="text-t66-text-muted text-[0.85rem] mt-1.5">
              <%= if @participant.start_date && @participant.end_date do %>
                <strong class="text-t66-text-secondary">
                  {Calendar.strftime(@participant.start_date, "%b %d, %Y")}
                </strong>
                →
                <strong class="text-t66-text-secondary">
                  {Calendar.strftime(@participant.end_date, "%b %d, %Y")}
                </strong>
              <% end %>
            </div>
          </div>
          <%!-- Fail button --%>
          <%= if @participant.status == :active do %>
            <button
              phx-click="show_fail_modal"
              class="px-5 py-2.5 rounded-[10px] border border-[rgba(239,68,68,0.3)] bg-[rgba(239,68,68,0.12)] text-[#ef4444] text-[0.75rem] font-bold tracking-[1.5px] uppercase cursor-pointer transition-all hover:bg-[#ef4444] hover:text-white hover:border-[#ef4444] whitespace-nowrap"
            >
              ✕ Fail Challenge
            </button>
          <% end %>
        </div>

        <%!-- Progress bar --%>
        <%= if @challenge_started do %>
          <div>
            <div class="flex justify-between items-baseline mb-2">
              <span class="text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted">
                Progress
              </span>
              <span class="font-display text-[1.4rem] text-t66-accent">{@progress_pct}%</span>
            </div>
            <div class="h-2.5 rounded-full bg-[rgba(255,255,255,0.05)] overflow-hidden relative">
              <div
                class="h-full rounded-full bg-gradient-to-r from-t66-accent to-[#ff8a50] transition-[width] duration-1000 relative"
                style={"width: #{@progress_pct}%"}
              >
                <div class="absolute top-0 right-0 bottom-0 w-5 bg-gradient-to-r from-transparent to-[rgba(255,255,255,0.2)] rounded-r-full">
                </div>
              </div>
            </div>
            <div class="text-[0.8rem] text-t66-text-muted mt-2 text-center">
              Day <strong class="text-t66-text">{@days_elapsed}</strong>
              of <strong class="text-t66-text">{@total_days}</strong>
            </div>
          </div>
        <% else %>
          <div class="text-center py-4">
            <p class="text-t66-text-muted text-sm">
              Challenge starts on
              <strong class="text-t66-text">
                {Calendar.strftime(@participant.start_date, "%b %d, %Y")}
              </strong>
            </p>
          </div>
        <% end %>

        <%!-- Failed reason --%>
        <%= if @participant.status == :failed && @participant.failure_reason do %>
          <div class="mt-4 p-4 rounded-xl bg-[rgba(239,68,68,0.12)] border border-[rgba(239,68,68,0.2)]">
            <p class="text-[#ef4444] text-sm">
              <strong>Reason:</strong> {@participant.failure_reason}
            </p>
          </div>
        <% end %>

        <%!-- Start again from template link --%>
        <%= if @participant.status in [:failed, :cancelled] && @challenge.template_id do %>
          <div class="mt-4">
            <.link
              navigate={~p"/challenges/#{@challenge.template_id}"}
              class="inline-flex items-center gap-2 text-t66-accent hover:text-t66-accent-secondary font-bold text-sm transition-colors"
            >
              <.icon name="hero-arrow-path" class="w-4 h-4" /> Start again from template
            </.link>
          </div>
        <% end %>
      </div>

      <%!-- ═══ SECTION 2: MOOD TRACKER ═══ --%>
      <%= if @challenge_started do %>
        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7">
          <h2 class="font-display text-[1.4rem] tracking-[2px] text-t66-text mb-1">
            Mood Tracker
          </h2>
          <p class="text-t66-text-muted text-[0.8rem] mb-4">
            Your emotional journey through {@total_days} days
          </p>

          <%!-- Phase labels --%>
          <div class="flex mb-1.5">
            <div class={[
              "flex-1 text-center text-[0.55rem] uppercase tracking-[1.5px] py-1 border-b-2",
              if(@days_elapsed <= 22,
                do: "text-t66-accent border-t66-accent",
                else: "text-t66-text-muted border-[rgba(255,255,255,0.06)]"
              )
            ]}>
              Destruction (1–22)
            </div>
            <div class={[
              "flex-1 text-center text-[0.55rem] uppercase tracking-[1.5px] py-1 border-b-2",
              if(@days_elapsed > 22 && @days_elapsed <= 44,
                do: "text-t66-accent border-t66-accent",
                else: "text-t66-text-muted border-[rgba(255,255,255,0.06)]"
              )
            ]}>
              Installation (23–44)
            </div>
            <div class={[
              "flex-1 text-center text-[0.55rem] uppercase tracking-[1.5px] py-1 border-b-2",
              if(@days_elapsed > 44,
                do: "text-t66-accent border-t66-accent",
                else: "text-t66-text-muted border-[rgba(255,255,255,0.06)]"
              )
            ]}>
              Integration (45–66)
            </div>
          </div>

          <%!-- 66-day mood grid --%>
          <div class="mood-grid-22 mt-3">
            <%= for day <- 1..@total_days do %>
              <% is_future = day > @days_elapsed %>
              <% is_today = day == @days_elapsed %>
              <% mood = Map.get(@mood_history, day) %>
              <div
                class={[
                  "aspect-square rounded-lg flex items-center justify-center text-[clamp(0.7rem,1.2vw,1.1rem)] cursor-default relative transition-transform hover:scale-[1.2] hover:z-[2]",
                  mood_tile_class(mood, is_future),
                  is_today && "ring-2 ring-t66-accent"
                ]}
                title={"Day #{day}#{if mood, do: " — #{mood_label(mood)}", else: ""}"}
              >
                <%= cond do %>
                  <% is_future -> %>
                    <span class="text-[0.55rem] text-t66-text-muted opacity-40">{day}</span>
                  <% mood in ["good", "neutral"] -> %>
                    {mood_emoji(mood)}
                  <% mood == "upset" -> %>
                    {mood_emoji(mood)}
                  <% true -> %>
                    <span class="text-[0.6rem] text-t66-text-muted">·</span>
                <% end %>
              </div>
            <% end %>
          </div>

          <%!-- Legend --%>
          <div class="flex gap-4 mt-3.5 flex-wrap">
            <div class="flex items-center gap-1.5 text-[0.7rem] text-t66-text-muted">
              <div class="w-3 h-3 rounded bg-[rgba(34,197,94,0.12)]"></div> Good
            </div>
            <div class="flex items-center gap-1.5 text-[0.7rem] text-t66-text-muted">
              <div class="w-3 h-3 rounded bg-[rgba(234,179,8,0.12)]"></div> Okay
            </div>
            <div class="flex items-center gap-1.5 text-[0.7rem] text-t66-text-muted">
              <div class="w-3 h-3 rounded bg-[rgba(239,68,68,0.12)]"></div> Not Good
            </div>
            <div class="flex items-center gap-1.5 text-[0.7rem] text-t66-text-muted">
              <div class="w-3 h-3 rounded bg-[rgba(255,255,255,0.03)]"></div> No Mood
            </div>
          </div>
        </div>
      <% end %>

      <%!-- ═══ SECTION 3: TODAY'S TASKS ═══ --%>
      <%= if @challenge_started && @participant.status == :active do %>
        <%!-- Missed days warning --%>
        <%= if @missed_days != [] do %>
          <div class="bg-t66-card border border-[rgba(234,179,8,0.2)] rounded-2xl p-6">
            <h3 class="font-display text-[1.1rem] tracking-[2px] text-[#eab308] mb-3">
              Missed Check-ins
            </h3>
            <%= if length(@missed_days) >= 5 do %>
              <p class="text-[#ef4444] text-sm mb-3 font-bold">
                Warning: {length(@missed_days)} missed days! Auto-fail triggers at 7 consecutive missed days.
              </p>
            <% end %>
            <div class="flex flex-wrap gap-2">
              <%= for {date, day_num} <- Enum.take(@missed_days, 10) do %>
                <button
                  phx-click="check_in_missed_day"
                  phx-value-date={Date.to_iso8601(date)}
                  class="px-3 py-1.5 rounded-lg border border-[rgba(234,179,8,0.3)] bg-[rgba(234,179,8,0.08)] text-[#eab308] text-xs font-bold hover:bg-[rgba(234,179,8,0.2)] transition-colors"
                >
                  Day {day_num} · {Calendar.strftime(date, "%b %d")}
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7">
          <div class="flex justify-between items-center mb-5 flex-wrap gap-2.5">
            <h2 class="font-display text-[1.4rem] tracking-[2px] text-t66-text">
              Today's Tasks
            </h2>
            <span class="font-display text-[1rem] tracking-[2px] text-t66-accent bg-[rgba(255,77,0,0.15)] px-3.5 py-1 rounded-full">
              Day {@days_elapsed}
            </span>
          </div>

          <%= if @has_checked_in do %>
            <%!-- Already checked in --%>
            <div class="text-center py-8">
              <div class="text-4xl mb-3">✓</div>
              <p class="font-display text-[1.2rem] tracking-[2px] text-[#22c55e]">
                Day {@days_elapsed} Completed!
              </p>
              <p class="text-t66-text-muted text-sm mt-2">
                Come back tomorrow for your next check-in.
              </p>
            </div>
          <% else %>
            <%!-- Task list --%>
            <%= case @today_items do %>
              <% {:tasks, tasks} -> %>
                <%= if Enum.empty?(tasks) do %>
                  <p class="text-t66-text-muted text-sm text-center py-6">
                    No tasks scheduled for today. Enjoy your rest day!
                  </p>
                <% else %>
                  <div class="flex flex-col gap-2.5 mb-6">
                    <%= for task <- tasks do %>
                      <% status = get_task_status_today(@participant.id, task.id) %>
                      <div class={[
                        "flex items-center gap-3.5 p-3.5 rounded-xl border transition-all",
                        task_row_class(status)
                      ]}>
                        <span class="text-[1.1rem] w-6 text-center flex-shrink-0">
                          {task_emoji(task.schedule_type)}
                        </span>
                        <span class={[
                          "flex-1 text-[0.9rem] font-medium",
                          task_name_class(status)
                        ]}>
                          {task.title}
                        </span>
                        <%= case status do %>
                          <% :accomplished -> %>
                            <span class="text-[0.6rem] uppercase tracking-[1.5px] font-bold px-2.5 py-1 rounded-md text-[#22c55e] bg-[rgba(34,197,94,0.12)]">
                              ✓ Done
                            </span>
                          <% :failed -> %>
                            <span class="text-[0.6rem] uppercase tracking-[1.5px] font-bold px-2.5 py-1 rounded-md text-[#ef4444] bg-[rgba(239,68,68,0.12)]">
                              ✕ Failed
                            </span>
                          <% _ -> %>
                            <div class="flex gap-1.5 flex-shrink-0">
                              <button
                                phx-click="complete_task"
                                phx-value-task-id={task.id}
                                class="w-[34px] h-[34px] rounded-lg border border-[rgba(255,255,255,0.06)] bg-transparent flex items-center justify-center text-[0.85rem] text-[#22c55e] cursor-pointer transition-all hover:bg-[rgba(34,197,94,0.12)] hover:border-[rgba(34,197,94,0.3)]"
                                title="Done"
                              >
                                ✓
                              </button>
                              <button
                                phx-click="fail_task"
                                phx-value-task-id={task.id}
                                class="w-[34px] h-[34px] rounded-lg border border-[rgba(255,255,255,0.06)] bg-transparent flex items-center justify-center text-[0.85rem] text-[#ef4444] cursor-pointer transition-all hover:bg-[rgba(239,68,68,0.12)] hover:border-[rgba(239,68,68,0.3)]"
                                title="Failed"
                              >
                                ✕
                              </button>
                            </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              <% _ -> %>
                <p class="text-t66-text-muted text-sm text-center py-6">Loading tasks...</p>
            <% end %>

            <%!-- Mood selector --%>
            <div class="mb-6">
              <div class="text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2.5">
                How are you feeling today?
              </div>
              <div class="flex gap-2.5">
                <%= for {key, emoji, label} <- [{"good", "😊", "Good"}, {"neutral", "😐", "Okay"}, {"upset", "😞", "Not Good"}] do %>
                  <button
                    phx-click="select_mood"
                    phx-value-mood={key}
                    class={[
                      "w-14 h-14 rounded-[14px] border-2 flex items-center justify-center text-[1.6rem] cursor-pointer transition-all relative hover:scale-110",
                      mood_button_class(key, @check_in_mood)
                    ]}
                  >
                    {emoji}
                    <span class="absolute -bottom-[18px] text-[0.55rem] uppercase tracking-[1px] text-t66-text-muted whitespace-nowrap">
                      {label}
                    </span>
                  </button>
                <% end %>
              </div>
            </div>

            <%!-- Reflection --%>
            <div class="mb-7 mt-3">
              <div class="text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2.5">
                Daily Reflection
              </div>
              <textarea
                phx-change="update_check_in_note"
                phx-debounce="300"
                name="value"
                value={@check_in_note}
                placeholder="How was your day? What did you learn?"
                class="w-full min-h-[100px] p-3.5 bg-[#0f0f0f] border border-[rgba(255,255,255,0.08)] rounded-xl text-t66-text font-sans text-[0.9rem] outline-none resize-y focus:border-[rgba(255,77,0,0.4)] transition-colors placeholder:text-t66-text-muted"
              >{@check_in_note}</textarea>
            </div>

            <%!-- Finish Day button --%>
            <button
              phx-click="finish_day"
              class="w-full py-[18px] border-none rounded-[14px] bg-t66-accent text-white font-bold text-[0.9rem] tracking-[2px] uppercase cursor-pointer transition-all shadow-[0_0_40px_rgba(255,77,0,0.2)] flex items-center justify-center gap-2.5 hover:translate-y-[-2px] hover:shadow-[0_0_60px_rgba(255,77,0,0.35)] active:translate-y-0"
            >
              🔥 Finish Day {@days_elapsed}
            </button>
          <% end %>
        </div>
      <% end %>

      <%!-- ═══ SECTION 4: CHALLENGE FEED ═══ --%>
      <%= if @feed != [] do %>
        <div class="mb-10">
          <div class="flex justify-between items-center mb-5">
            <h2 class="font-display text-[1.6rem] tracking-[2px] text-t66-text">
              Challenge Feed
            </h2>
            <span class={[
              "text-[0.6rem] uppercase tracking-[2px] font-bold px-3 py-1 rounded-full",
              if(@challenge.visibility == :public,
                do: "text-[#22c55e] bg-[rgba(34,197,94,0.12)]",
                else: "text-t66-text-muted bg-[rgba(255,255,255,0.04)]"
              )
            ]}>
              <%= if @challenge.visibility == :public do %>
                🌍 Public
              <% else %>
                🔒 Private
              <% end %>
            </span>
          </div>

          <div class="flex flex-col gap-4">
            <%= for check_in <- @feed do %>
              <.feed_entry
                check_in={check_in}
                current_user_id={@current_user_id}
                expanded_check_in_comments={@expanded_check_in_comments}
              />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>

    <%!-- Fail Challenge Modal --%>
    <%= if @show_fail_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-8 max-w-md w-full mx-4">
          <h3 class="font-display text-[1.4rem] tracking-[2px] text-t66-text mb-4">
            Fail Challenge
          </h3>
          <p class="text-t66-text-secondary text-sm mb-6">
            Are you sure you want to fail this challenge? This cannot be undone.
          </p>
          <div class="mb-6">
            <label class="text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted font-bold block mb-2">
              Reason (optional)
            </label>
            <textarea
              phx-change="update_failure_reason"
              phx-debounce="300"
              name="value"
              value={@failure_reason}
              placeholder="Why are you failing this challenge?"
              class="w-full min-h-[80px] p-3 bg-[#0f0f0f] border border-[rgba(255,255,255,0.08)] rounded-xl text-t66-text text-sm outline-none resize-y focus:border-[rgba(255,77,0,0.4)] placeholder:text-t66-text-muted"
            >{@failure_reason}</textarea>
          </div>
          <div class="flex gap-3">
            <button
              phx-click="close_fail_modal"
              class="flex-1 py-3 rounded-xl border border-[rgba(255,255,255,0.06)] text-t66-text-secondary text-sm font-bold hover:bg-[rgba(255,255,255,0.04)] transition-colors"
            >
              Cancel
            </button>
            <button
              phx-click="confirm_fail_challenge"
              class="flex-1 py-3 rounded-xl bg-[#ef4444] text-white text-sm font-bold hover:bg-[#dc2626] transition-colors"
            >
              Fail Challenge
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # ============================================================================
  # Feed Entry Component
  # ============================================================================

  defp feed_entry(assigns) do
    check_in = assigns.check_in
    total = Map.get(check_in, :total_tasks, 0)
    done = Map.get(check_in, :completed_tasks, 0)
    failed = Map.get(check_in, :failed_tasks, 0)
    done_pct = if total > 0, do: round(done / total * 100), else: 0
    fail_pct = if total > 0, do: round(failed / total * 100), else: 0

    assigns =
      assigns
      |> assign(:total, total)
      |> assign(:done, done)
      |> assign(:failed, failed)
      |> assign(:done_pct, done_pct)
      |> assign(:fail_pct, fail_pct)

    ~H"""
    <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-6 transition-all hover:border-[rgba(255,255,255,0.08)]">
      <%!-- Top: date + mood --%>
      <div class="flex justify-between items-center mb-3.5">
        <div>
          <div class="font-bold text-[0.95rem] text-t66-text">
            {Calendar.strftime(@check_in.completed_date, "%b %d, %Y")}
          </div>
          <div class="font-display text-[0.85rem] text-t66-accent tracking-[2px]">
            DAY {@check_in.day_number}
          </div>
        </div>
        <%= if @check_in.mood do %>
          <span class={[
            "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[0.75rem] font-semibold",
            feed_mood_class(@check_in.mood)
          ]}>
            {mood_emoji(@check_in.mood)} {mood_label(@check_in.mood)}
          </span>
        <% end %>
      </div>

      <%!-- Task stats --%>
      <%= if @total > 0 do %>
        <div class="flex gap-4 mb-3 flex-wrap">
          <div class="text-[0.8rem] text-t66-text-muted">
            <strong class="text-t66-text">{@done}</strong> / {@total} tasks done
          </div>
          <%= if @failed > 0 do %>
            <div class="text-[0.8rem] text-t66-text-muted">
              <strong class="text-t66-text">{@failed}</strong> failed
            </div>
          <% end %>
        </div>
        <%!-- Task completion bar --%>
        <div class="h-1.5 rounded-full bg-[rgba(255,255,255,0.05)] overflow-hidden flex mb-1.5">
          <div class="h-full bg-[#22c55e]" style={"width: #{@done_pct}%"}></div>
          <div class="h-full bg-[#ef4444]" style={"width: #{@fail_pct}%"}></div>
        </div>
        <div class="text-[0.7rem] text-t66-text-muted mb-3">{@done_pct}% completion rate</div>
      <% end %>

      <%!-- Reflection --%>
      <%= if @check_in.note do %>
        <div class="p-3 bg-[#0a0a0a] rounded-[10px] border-l-[3px] border-[rgba(255,255,255,0.06)] text-t66-text-secondary text-[0.85rem] italic leading-relaxed mb-4">
          "{@check_in.note}"
        </div>
      <% end %>

      <%!-- Actions: like + comment --%>
      <div class="flex items-center gap-[18px] pt-3.5 border-t border-[rgba(255,255,255,0.06)]">
        <%= if @current_user_id && @current_user_id != @check_in.user_id do %>
          <button
            phx-click="toggle_check_in_like"
            phx-value-check-in-id={@check_in.id}
            class={[
              "flex items-center gap-1.5 bg-none border-none text-[0.8rem] cursor-pointer transition-all p-1.5 rounded-lg hover:bg-[rgba(255,255,255,0.04)]",
              if(Map.get(@check_in, :user_liked, false),
                do: "text-[#ef4444]",
                else: "text-t66-text-muted hover:text-t66-text"
              )
            ]}
          >
            <span class="text-[1rem]">
              {if Map.get(@check_in, :user_liked, false), do: "❤️", else: "🤍"}
            </span>
            {Map.get(@check_in, :like_count, 0)}
          </button>
        <% else %>
          <span class="flex items-center gap-1.5 text-[0.8rem] text-t66-text-muted p-1.5">
            <span class="text-[1rem]">🤍</span>
            {Map.get(@check_in, :like_count, 0)}
          </span>
        <% end %>

        <button
          phx-click="toggle_check_in_comments"
          phx-value-check-in-id={@check_in.id}
          class="flex items-center gap-1.5 bg-none border-none text-t66-text-muted text-[0.8rem] cursor-pointer transition-all p-1.5 rounded-lg hover:bg-[rgba(255,255,255,0.04)] hover:text-t66-text"
        >
          <span class="text-[1rem]">💬</span>
          {Map.get(@check_in, :comment_count, 0)}
        </button>
      </div>

      <%!-- Comments section --%>
      <%= if MapSet.member?(@expanded_check_in_comments, @check_in.id) do %>
        <div class="mt-3.5 pt-3.5 border-t border-[rgba(255,255,255,0.06)]">
          <%= for comment <- Map.get(@check_in, :comments, []) do %>
            <div class="flex gap-2.5 mb-3">
              <div class="w-[30px] h-[30px] rounded-full bg-[rgba(255,255,255,0.06)] flex items-center justify-center font-display text-[0.6rem] text-t66-text-muted tracking-[1px] flex-shrink-0">
                {String.slice(comment.user.name || comment.user.user_name || "U", 0, 2)
                |> String.upcase()}
              </div>
              <div class="flex-1">
                <div class="flex items-start justify-between gap-2">
                  <span class="font-bold text-[0.8rem] text-t66-text">
                    {comment.user.name || comment.user.user_name}
                    <span class="text-t66-text-muted font-normal ml-1.5 text-[0.7rem]">
                      {Calendar.strftime(comment.inserted_at, "%b %d")}
                    </span>
                  </span>
                  <%= if @current_user_id == comment.user_id do %>
                    <button
                      phx-click="delete_check_in_comment"
                      phx-value-comment-id={comment.id}
                      phx-value-check-in-id={@check_in.id}
                      class="text-t66-text-muted hover:text-[#ef4444] transition-colors text-xs"
                    >
                      ✕
                    </button>
                  <% end %>
                </div>
                <p class="text-[0.82rem] text-t66-text-secondary mt-0.5">{comment.content}</p>
              </div>
            </div>
          <% end %>
          <%= if Enum.empty?(Map.get(@check_in, :comments, [])) do %>
            <p class="text-xs text-t66-text-muted text-center py-3">No comments yet</p>
          <% end %>

          <form phx-submit="add_check_in_comment" class="flex gap-2 mt-2.5">
            <input type="hidden" name="check-in-id" value={@check_in.id} />
            <input
              type="text"
              name="content"
              placeholder="Write a comment..."
              maxlength="500"
              required
              class="flex-1 px-3.5 py-2.5 bg-[#0f0f0f] border border-[rgba(255,255,255,0.08)] rounded-[10px] text-t66-text text-[0.8rem] outline-none focus:border-[rgba(255,77,0,0.3)]"
            />
            <button
              type="submit"
              class="w-[38px] h-[38px] rounded-[10px] border-none bg-t66-accent text-white text-[0.9rem] cursor-pointer transition-all flex items-center justify-center hover:scale-105"
            >
              →
            </button>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  defp refresh_progress(socket, challenge, participant, flash) do
    progress = Challenges.get_participant_progress(participant.id)
    today_items = Challenges.get_today_items(challenge.id, participant.id)

    socket
    |> assign(:progress, progress)
    |> assign(:today_items, today_items)
    |> recalc_progress()
    |> put_flash(:info, flash)
  end

  defp refresh_after_check_in(socket, flash_message) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    updated_challenge = Challenges.get_challenge_for_display(challenge.id)
    updated_participant = Challenges.get_participant(challenge.id, participant.user_id)
    feed = Challenges.get_challenge_feed(challenge.id, socket.assigns.current_user_id)
    progress = Challenges.get_participant_progress(participant.id)
    mood_history = Challenges.get_mood_history(participant.id)
    missed_days = Challenges.get_missed_check_in_days(participant.id)
    has_checked_in = Challenges.has_checked_in_today?(participant.id)

    {:noreply,
     socket
     |> assign(:challenge, updated_challenge)
     |> assign(:participant, updated_participant)
     |> assign(:has_checked_in, has_checked_in)
     |> assign(:check_in_note, "")
     |> assign(:check_in_mood, nil)
     |> assign(:feed, feed)
     |> assign(:progress, progress)
     |> assign(:mood_history, mood_history)
     |> assign(:missed_days, missed_days)
     |> recalc_progress()
     |> put_flash(:info, flash_message)}
  end

  defp recalc_progress(socket) do
    progress = socket.assigns.progress
    total_days = socket.assigns.total_days
    days_elapsed = if progress, do: Map.get(progress, :days_elapsed, 0), else: 0
    progress_pct = if total_days > 0, do: min(round(days_elapsed / total_days * 100), 100), else: 0

    socket
    |> assign(:days_elapsed, days_elapsed)
    |> assign(:progress_pct, progress_pct)
  end

  defp update_check_in_in_feed(feed, check_in_id, update_fn) do
    Enum.map(feed, fn ci ->
      if ci.id == check_in_id, do: update_fn.(ci), else: ci
    end)
  end

  defp get_task_status_today(participant_id, task_id) do
    Challenges.get_task_status(participant_id, task_id, Date.utc_today())
  end

  defp calculate_challenge_duration(challenge) do
    cond do
      challenge.duration_days -> challenge.duration_days
      challenge.start_date && challenge.end_date -> Date.diff(challenge.end_date, challenge.start_date)
      true -> 66
    end
  end

  # Styling helpers
  defp status_badge_class(:active), do: "text-t66-accent bg-[rgba(255,77,0,0.15)]"
  defp status_badge_class(:completed), do: "text-[#22c55e] bg-[rgba(34,197,94,0.12)]"
  defp status_badge_class(:failed), do: "text-[#ef4444] bg-[rgba(239,68,68,0.12)]"
  defp status_badge_class(:cancelled), do: "text-t66-text-muted bg-[rgba(255,255,255,0.04)]"
  defp status_badge_class(_), do: "text-t66-text-muted bg-[rgba(255,255,255,0.04)]"

  defp status_label(:active), do: "Active"
  defp status_label(:completed), do: "Completed"
  defp status_label(:failed), do: "Failed"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(_), do: "Unknown"

  defp mood_tile_class("good", false), do: "bg-[rgba(34,197,94,0.12)]"
  defp mood_tile_class("neutral", false), do: "bg-[rgba(234,179,8,0.12)]"
  defp mood_tile_class("upset", false), do: "bg-[rgba(239,68,68,0.12)]"
  defp mood_tile_class(nil, true), do: "bg-[rgba(255,255,255,0.015)] opacity-40"
  defp mood_tile_class(_, true), do: "bg-[rgba(255,255,255,0.015)] opacity-40"
  defp mood_tile_class(_, false), do: "bg-[rgba(255,255,255,0.03)]"

  defp mood_emoji("good"), do: "😊"
  defp mood_emoji("neutral"), do: "😐"
  defp mood_emoji("upset"), do: "😞"
  defp mood_emoji(_), do: "·"

  defp mood_label("good"), do: "Good"
  defp mood_label("neutral"), do: "Okay"
  defp mood_label("upset"), do: "Not Good"
  defp mood_label(_), do: "No Mood"

  defp feed_mood_class("good"), do: "text-[#22c55e] bg-[rgba(34,197,94,0.12)]"
  defp feed_mood_class("neutral"), do: "text-[#eab308] bg-[rgba(234,179,8,0.12)]"
  defp feed_mood_class("upset"), do: "text-[#ef4444] bg-[rgba(239,68,68,0.12)]"
  defp feed_mood_class(_), do: "text-t66-text-muted bg-[rgba(255,255,255,0.04)]"

  defp task_row_class(:accomplished),
    do: "bg-[#0a0a0a] border-[rgba(255,255,255,0.06)]"

  defp task_row_class(:failed),
    do: "bg-[#0a0a0a] border-[rgba(255,255,255,0.06)]"

  defp task_row_class(_),
    do: "bg-[#0a0a0a] border-[rgba(255,255,255,0.06)] hover:border-[rgba(255,255,255,0.1)]"

  defp task_name_class(:accomplished), do: "text-t66-text-muted line-through"
  defp task_name_class(:failed), do: "text-[#ef4444] line-through opacity-60"
  defp task_name_class(_), do: "text-t66-text"

  defp task_emoji(:daily), do: "🎯"
  defp task_emoji(:twice_week), do: "📅"
  defp task_emoji(:every_other_day), do: "🔄"
  defp task_emoji(:mon_fri), do: "💼"
  defp task_emoji(:custom_weekdays), do: "📊"
  defp task_emoji(_), do: "✍️"

  defp mood_button_class(key, selected) when key == selected do
    case key do
      "good" ->
        "border-[#22c55e] bg-[rgba(34,197,94,0.12)] shadow-[0_0_20px_rgba(34,197,94,0.2)] scale-110"

      "neutral" ->
        "border-[#eab308] bg-[rgba(234,179,8,0.12)] shadow-[0_0_20px_rgba(234,179,8,0.2)] scale-110"

      "upset" ->
        "border-[#ef4444] bg-[rgba(239,68,68,0.12)] shadow-[0_0_20px_rgba(239,68,68,0.2)] scale-110"

      _ ->
        "border-[rgba(255,255,255,0.06)]"
    end
  end

  defp mood_button_class(_, _), do: "border-[rgba(255,255,255,0.06)] bg-transparent"
end
