defmodule HeadsUpWeb.ChallengeLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Challenges, Reports}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    challenge = Challenges.get_challenge_for_display(id)
    current_user = socket.assigns[:current_user]

    if is_nil(challenge) do
      {:ok,
       socket
       |> put_flash(:error, "Challenge not found")
       |> push_navigate(to: ~p"/challenges")}
    else
      # Check visibility
      can_view =
        (is_nil(current_user) && challenge.visibility == :public) ||
          (current_user && Challenges.can_view_challenge?(challenge, current_user.id))

      if can_view do
        participant = current_user && Challenges.get_participant(challenge.id, current_user.id)
        progress = participant && Challenges.get_participant_progress(participant.id)

        # For templates, check if user already started a challenge from this template
        {user_challenge_from_template, template_starters, grouped_starters, template_stats} =
          if challenge.is_template do
            user_ch =
              if current_user,
                do: Challenges.get_user_challenge_from_template(challenge.id, current_user.id),
                else: nil

            starters = Challenges.get_template_starters(challenge.id)
            grouped = Challenges.group_starters_by_status(starters)
            stats = Challenges.template_success_rate(grouped)
            {user_ch, starters, grouped, stats}
          else
            {nil, [], %{active: [], completed: [], failed: []},
             %{total: 0, completed: 0, failed: 0, active: 0, success_rate: 0.0}}
          end

        # For active personal challenges: check auto-fail (7 missed days)
        {participant, challenge} =
          if participant && participant.status == :active && !challenge.is_template do
            case Challenges.check_and_auto_fail(participant.id) do
              {:ok, :auto_failed} ->
                # Reload after auto-fail
                updated_challenge = Challenges.get_challenge_for_display(challenge.id)
                updated_participant = Challenges.get_participant(challenge.id, current_user.id)
                {updated_participant, updated_challenge}

              _ ->
                {participant, challenge}
            end
          else
            {participant, challenge}
          end

        # Recalculate progress after potential auto-fail
        progress = participant && Challenges.get_participant_progress(participant.id)

        # For personal challenges: get today's items, check-in status, feed, mood, and missed days
        {today_items, has_checked_in, feed, mood_history, missed_days} =
          if participant && !challenge.is_template do
            items = Challenges.get_today_items(challenge.id, participant.id)
            checked_in = Challenges.has_checked_in_today?(participant.id)
            current_user_id = if current_user, do: current_user.id, else: nil
            challenge_feed = Challenges.get_challenge_feed(challenge.id, current_user_id)
            moods = Challenges.get_mood_history(participant.id)
            missed = Challenges.get_missed_check_in_days(participant.id)
            {items, checked_in, challenge_feed, moods, missed}
          else
            {nil, false, [], %{}, []}
          end

        # Check if the challenge has actually started (start_date <= today)
        challenge_started =
          participant != nil && participant.start_date != nil &&
            Date.compare(Date.utc_today(), participant.start_date) != :lt

        socket =
          socket
          |> assign(:challenge, challenge)
          |> assign(:participant, participant)
          |> assign(:progress, progress)
          |> assign(:page_title, challenge.title)
          |> assign(:show_join_modal, false)
          |> assign(:join_start_date, Date.to_iso8601(Date.utc_today()))
          |> assign(:user_challenge_from_template, user_challenge_from_template)
          |> assign(:template_starters, template_starters)
          |> assign(:grouped_starters, grouped_starters)
          |> assign(:template_stats, template_stats)
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
          |> assign(:current_user_id, if(current_user, do: current_user.id, else: nil))
          |> assign(:expanded_check_in_comments, MapSet.new())
          |> assign(:show_report_modal, false)
          |> assign(:report_reason, "")
          |> assign(:report_description, "")

        {:ok, socket, layout: {HeadsUpWeb.Layouts, :public}}
      else
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this challenge")
         |> push_navigate(to: ~p"/challenges")}
      end
    end
  end

  # ============================================================================
  # Join/Start Events
  # ============================================================================

  @impl true
  def handle_event("show_join_modal", _params, socket) do
    challenge = socket.assigns.challenge

    if challenge.type == :predefined do
      {:noreply, assign(socket, :show_join_modal, true)}
    else
      handle_do_join(socket, nil)
    end
  end

  @impl true
  def handle_event("close_join_modal", _params, socket) do
    {:noreply, assign(socket, :show_join_modal, false)}
  end

  @impl true
  def handle_event("update_join_date", %{"value" => value}, socket) do
    {:noreply, assign(socket, :join_start_date, value)}
  end

  @impl true
  def handle_event("confirm_join", _params, socket) do
    start_date =
      case Date.from_iso8601(socket.assigns.join_start_date) do
        {:ok, date} -> date
        _ -> Date.utc_today()
      end

    socket = assign(socket, :show_join_modal, false)
    handle_do_join(socket, start_date)
  end

  @impl true
  def handle_event("join_challenge", _params, socket) do
    handle_event("show_join_modal", %{}, socket)
  end

  defp handle_do_join(socket, start_date) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    if current_user do
      opts = if start_date, do: [start_date: start_date], else: []

      case Challenges.join_challenge(challenge.id, current_user.id, opts) do
        {:ok, participant} ->
          progress = Challenges.get_participant_progress(participant.id)

          {:noreply,
           socket
           |> assign(:participant, participant)
           |> assign(:progress, progress)
           |> put_flash(:info, "Successfully joined the challenge!")}

        {:error, :already_joined} ->
          {:noreply, put_flash(socket, :error, "You've already joined this challenge.")}

        {:error, :active_limit_reached} ->
          {:noreply,
           put_flash(socket, :error, "You've reached the maximum of 3 active goals/challenges.")}

        {:error, :access_denied} ->
          {:noreply, put_flash(socket, :error, "You don't have access to this challenge.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not join challenge.")}
      end
    else
      {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_event("start_challenge", _params, socket) do
    challenge = socket.assigns.challenge
    current_user = socket.assigns.current_user

    if current_user do
      if challenge.is_template do
        {:noreply, assign(socket, :show_join_modal, true)}
      else
        {:noreply, put_flash(socket, :error, "This is not a template.")}
      end
    else
      {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_event("confirm_start_challenge", _params, socket) do
    challenge = socket.assigns.challenge
    current_user = socket.assigns.current_user

    start_date =
      case Date.from_iso8601(socket.assigns.join_start_date) do
        {:ok, date} -> date
        _ -> Date.utc_today()
      end

    case Challenges.start_challenge_from_template(challenge.id, current_user.id, start_date) do
      {:ok, new_challenge} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:info, "Challenge started! Good luck!")
         |> push_navigate(to: ~p"/challenges/#{new_challenge.id}")}

      {:error, :not_a_template} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:error, "This is not a template.")}

      {:error, :active_limit_reached} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(
           :error,
           "You've reached the maximum of 3 active goals/challenges. Complete or remove one to start a new challenge."
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:error, "Could not start challenge.")}
    end
  end

  # ============================================================================
  # Delete / Fail Events
  # ============================================================================

  @impl true
  def handle_event("delete_challenge", _params, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    case Challenges.delete_challenge(challenge, current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge deleted successfully.")
         |> push_navigate(to: ~p"/challenges")}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "You don't have permission to delete this challenge.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete challenge.")}
    end
  end

  @impl true
  def handle_event("share_as_template", _params, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    case Challenges.share_as_template(challenge.id, current_user.id) do
      {:ok, template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge shared as a community template!")
         |> push_navigate(to: ~p"/challenges/#{template.id}")}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "You don't have permission to share this challenge.")}

      {:error, :already_template} ->
        {:noreply, put_flash(socket, :error, "This challenge is already a template.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not share challenge as template.")}
    end
  end

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
    failure_reason = socket.assigns.failure_reason
    reason = if failure_reason == "", do: nil, else: failure_reason

    case Challenges.fail_challenge(challenge.id, current_user.id, reason) do
      {:ok, updated_challenge} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> assign(:challenge, Challenges.get_challenge_for_display(updated_challenge.id))
         |> assign(:participant, Challenges.get_participant(challenge.id, current_user.id))
         |> put_flash(:info, "Challenge marked as failed.")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> put_flash(:error, "You don't have permission to fail this challenge.")}

      {:error, :cannot_fail_template} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> put_flash(:error, "Cannot fail a template.")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_fail_modal, false)
         |> put_flash(:error, "Could not fail challenge.")}
    end
  end

  # ============================================================================
  # Cancel Challenge Event
  # ============================================================================

  @impl true
  def handle_event("cancel_challenge", _params, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    case Challenges.cancel_challenge(challenge.id, current_user.id) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> assign(:challenge, Challenges.get_challenge_for_display(challenge.id))
         |> assign(:participant, Challenges.get_participant(challenge.id, current_user.id))
         |> put_flash(:info, "Challenge cancelled.")}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "You don't have permission to cancel this challenge.")}

      {:error, :invalid_status} ->
        {:noreply, put_flash(socket, :error, "Challenge must be active to cancel.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not cancel challenge.")}
    end
  end

  # ============================================================================
  # Step / Task Progress Events
  # ============================================================================

  @impl true
  def handle_event("complete_step", %{"step-id" => step_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.complete_step(participant.id, String.to_integer(step_id)) do
      {:ok, _} ->
        updated_participant = Challenges.get_participant(challenge.id, participant.user_id)
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)
        updated_challenge = Challenges.get_challenge_for_display(challenge.id)

        {:noreply,
         socket
         |> assign(:participant, updated_participant)
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> assign(:challenge, updated_challenge)
         |> put_flash(:info, "Step completed!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete step.")}
    end
  end

  @impl true
  def handle_event("uncomplete_step", %{"step-id" => step_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.uncomplete_step(participant.id, String.to_integer(step_id)) do
      {:ok, _} ->
        updated_participant = Challenges.get_participant(challenge.id, participant.user_id)
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)
        updated_challenge = Challenges.get_challenge_for_display(challenge.id)

        {:noreply,
         socket
         |> assign(:participant, updated_participant)
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> assign(:challenge, updated_challenge)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not uncomplete step.")}
    end
  end

  @impl true
  def handle_event("complete_task", %{"task-id" => task_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.complete_task(participant.id, String.to_integer(task_id)) do
      {:ok, _} ->
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)

        {:noreply,
         socket
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> put_flash(:info, "Task completed for today!")}

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
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)

        {:noreply,
         socket
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> put_flash(:info, "Task marked as failed.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not mark task as failed.")}
    end
  end

  @impl true
  def handle_event("fail_step", %{"step-id" => step_id}, socket) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    case Challenges.fail_step(participant.id, String.to_integer(step_id)) do
      {:ok, _} ->
        updated_participant = Challenges.get_participant(challenge.id, participant.user_id)
        progress = Challenges.get_participant_progress(participant.id)
        today_items = Challenges.get_today_items(challenge.id, participant.id)
        updated_challenge = Challenges.get_challenge_for_display(challenge.id)

        {:noreply,
         socket
         |> assign(:participant, updated_participant)
         |> assign(:progress, progress)
         |> assign(:today_items, today_items)
         |> assign(:challenge, updated_challenge)
         |> put_flash(:info, "Step marked as failed.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not mark step as failed.")}
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
         |> assign(:today_items, today_items)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not uncomplete task.")}
    end
  end

  # ============================================================================
  # Daily Check-in Events
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
    check_in_note = socket.assigns.check_in_note
    check_in_mood = socket.assigns.check_in_mood
    note = if check_in_note == "", do: nil, else: check_in_note

    case Challenges.create_daily_check_in(participant.id, %{note: note, mood: check_in_mood}) do
      {:ok, _check_in} ->
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
      {:ok, _check_in} ->
        refresh_after_check_in(socket, "Checked in for #{date_str}!")

      {:error, :already_checked_in} ->
        {:noreply, put_flash(socket, :error, "Already checked in for that day.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not check in for that day.")}
    end
  end

  defp refresh_after_check_in(socket, flash_message) do
    participant = socket.assigns.participant
    challenge = socket.assigns.challenge

    # Reload everything - challenge may have been auto-completed
    updated_challenge = Challenges.get_challenge_for_display(challenge.id)
    updated_participant = Challenges.get_participant(challenge.id, participant.user_id)

    feed =
      Challenges.get_challenge_feed(challenge.id, socket.assigns.current_user_id)

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
     |> put_flash(:info, flash_message)}
  end

  # ============================================================================
  # Render
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class={[
          "rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow",
          if(@challenge.status == :failed,
            do: "bg-gradient-to-r from-slate-600 to-slate-700",
            else: "bg-gradient-to-r from-blue-600 to-indigo-600"
          )
        ]}>
          <div class="relative z-10">
            <%!-- Back Link --%>
            <.link
              navigate={~p"/challenges"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Challenges
            </.link>

            <%!-- Badges --%>
            <div class="flex flex-wrap items-center gap-2 mb-4">
              <%= if @challenge.is_template do %>
                <span class="bg-amber-400/30 text-amber-100 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider">
                  Template
                </span>
              <% end %>
              <span class={[
                "text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider",
                if(@challenge.type == :predefined,
                  do: "bg-purple-400/30 text-purple-100",
                  else: "bg-blue-400/30 text-blue-100"
                )
              ]}>
                {if @challenge.type == :predefined, do: "Official", else: "Community"}
              </span>
              <span class="bg-white/20 text-white/90 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider">
                {Phoenix.Naming.humanize(@challenge.visibility)}
              </span>
              <%= unless @challenge.is_template do %>
                <span class={[
                  "text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider",
                  case @challenge.status do
                    :active -> "bg-green-400/30 text-green-100"
                    :completed -> "bg-blue-400/30 text-blue-100"
                    :failed -> "bg-red-400/30 text-red-100"
                    _ -> "bg-white/20 text-white/80"
                  end
                ]}>
                  {Phoenix.Naming.humanize(@challenge.status)}
                </span>
              <% end %>
            </div>

            <%!-- Title --%>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-3 leading-tight">
              {@challenge.title}
            </h1>

            <%!-- Creator --%>
            <%= if @challenge.creator do %>
              <p class="text-blue-100 text-lg mb-4">
                Created by {@challenge.creator.name || @challenge.creator.user_name}
              </p>
            <% end %>

            <%!-- Meta Row --%>
            <div class="flex flex-wrap items-center gap-4 text-blue-100">
              <%= if @challenge.duration_days do %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-clock" class="w-5 h-5" />
                  {@challenge.duration_days} Day Challenge
                </span>
              <% end %>
              <%= if !@challenge.is_template && @challenge.start_date && @challenge.end_date do %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-calendar" class="w-5 h-5" />
                  {Calendar.strftime(@challenge.start_date, "%b %d")} - {Calendar.strftime(
                    @challenge.end_date,
                    "%b %d, %Y"
                  )}
                </span>
              <% end %>
              <%= if @challenge.is_template do %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-user-group" class="w-5 h-5" />
                  {@template_stats.total} started
                </span>
                <%= if @template_stats.completed > 0 do %>
                  <span class="flex items-center gap-1.5">
                    <.icon name="hero-trophy" class="w-5 h-5" />
                    {@template_stats.success_rate}% success rate
                  </span>
                <% end %>
              <% end %>
            </div>

            <%!-- Action Buttons --%>
            <%= if @current_user do %>
              <div class="flex flex-wrap gap-3 mt-8">
                <%= if @challenge.is_template do %>
                  <%= if @user_challenge_from_template && @user_challenge_from_template.status in [:active, :paused] do %>
                    <.link
                      navigate={~p"/challenges/#{@user_challenge_from_template.id}"}
                      class="inline-flex items-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold text-base hover:scale-105 transition-all"
                    >
                      <.icon name="hero-eye" class="w-5 h-5" /> View My Challenge
                    </.link>
                  <% else %>
                    <button
                      phx-click="start_challenge"
                      class="inline-flex items-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold text-base hover:scale-105 transition-all"
                    >
                      <.icon name="hero-play" class="w-5 h-5" />
                      {if @user_challenge_from_template, do: "Start Again", else: "Start Challenge"}
                    </button>
                  <% end %>
                <% else %>
                  <%= if @participant && @participant.status == :active do %>
                    <button
                      phx-click="show_fail_modal"
                      class="inline-flex items-center gap-2 bg-white/15 backdrop-blur-sm text-white border border-white/20 px-6 py-3 rounded-2xl font-bold text-sm hover:bg-white/25 transition-all"
                    >
                      <.icon name="hero-x-circle" class="w-5 h-5" /> Fail
                    </button>
                  <% end %>
                  <%= if !@challenge.is_template && @challenge.type != :predefined && @challenge.creator_user_id == @current_user.id do %>
                    <%= if is_nil(@challenge.template_id) && @challenge.status == :active do %>
                      <button
                        phx-click="share_as_template"
                        data-confirm="Share this challenge as a community template? Others will be able to start their own version."
                        class="inline-flex items-center gap-2 bg-white/15 backdrop-blur-sm text-white border border-white/20 px-6 py-3 rounded-2xl font-bold text-sm hover:bg-white/25 transition-all"
                      >
                        <.icon name="hero-share" class="w-5 h-5" /> Share with Community
                      </button>
                    <% else %>
                      <%= if @challenge.template_id do %>
                        <span class="inline-flex items-center gap-2 bg-white/10 text-white/60 border border-white/10 px-6 py-3 rounded-2xl font-bold text-sm cursor-default">
                          <.icon name="hero-check-circle" class="w-5 h-5" /> Already Shared
                        </span>
                      <% end %>
                    <% end %>
                  <% end %>
                <% end %>
                <%= if @challenge.creator_user_id == @current_user.id || @current_user.role in [:admin, "admin"] do %>
                  <button
                    phx-click="delete_challenge"
                    data-confirm="Are you sure you want to delete this challenge? This action cannot be undone."
                    class="inline-flex items-center gap-2 bg-red-500/20 text-red-100 border border-red-300/30 px-6 py-3 rounded-2xl font-bold text-sm hover:bg-red-500/30 transition-all"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" /> Delete
                  </button>
                <% end %>
                <%= if @challenge.creator_user_id != @current_user.id do %>
                  <button
                    phx-click="show_report_modal"
                    class="inline-flex items-center gap-2 bg-white/15 backdrop-blur-sm text-white border border-white/20 px-6 py-3 rounded-2xl font-bold text-sm hover:bg-red-500/30 transition-all"
                    title="Report challenge"
                  >
                    <.icon name="hero-flag" class="w-4 h-4" /> Report
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-bolt" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Template Status Banner --%>
        <%= if @challenge.is_template && @user_challenge_from_template do %>
          <%= case @user_challenge_from_template.status do %>
            <% status when status in [:active, :paused] -> %>
              <HeadsUpWeb.Components.UI.Card.card
                padding={:md}
                class="mb-8 border-green-200 bg-green-50"
              >
                <div class="flex items-center justify-between flex-wrap gap-4">
                  <div class="flex items-center gap-4">
                    <div class="w-12 h-12 bg-green-100 rounded-2xl flex items-center justify-center">
                      <.icon name="hero-check-circle" class="w-6 h-6 text-green-600" />
                    </div>
                    <div>
                      <p class="text-green-800 font-extrabold">
                        You've already started this challenge!
                      </p>
                      <p class="text-green-600 text-sm">
                        Started on {Calendar.strftime(
                          @user_challenge_from_template.start_date,
                          "%b %d, %Y"
                        )}
                      </p>
                    </div>
                  </div>
                  <.link
                    navigate={~p"/challenges/#{@user_challenge_from_template.id}"}
                    class="inline-flex items-center gap-2 bg-gradient-to-r from-green-500 to-emerald-600 text-white px-6 py-3 rounded-2xl font-bold text-sm hover:scale-105 transition-all"
                  >
                    Go to My Challenge
                  </.link>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% :completed -> %>
              <HeadsUpWeb.Components.UI.Card.card
                padding={:md}
                class="mb-8 border-amber-200 bg-amber-50"
              >
                <div class="flex items-center justify-between flex-wrap gap-4">
                  <div class="flex items-center gap-4">
                    <div class="w-12 h-12 bg-amber-100 rounded-2xl flex items-center justify-center">
                      <.icon name="hero-trophy" class="w-6 h-6 text-amber-600" />
                    </div>
                    <div>
                      <p class="text-amber-800 font-extrabold">You completed this challenge!</p>
                      <p class="text-amber-600 text-sm">
                        Great work! You can start it again if you'd like.
                      </p>
                    </div>
                  </div>
                  <.link
                    navigate={~p"/challenges/#{@user_challenge_from_template.id}"}
                    class="inline-flex items-center gap-2 bg-gradient-to-r from-amber-500 to-amber-600 text-white px-6 py-3 rounded-2xl font-bold text-sm hover:scale-105 transition-all"
                  >
                    View My Challenge
                  </.link>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% status when status in [:failed, :cancelled] -> %>
              <HeadsUpWeb.Components.UI.Card.card padding={:md} class="mb-8 border-red-200 bg-red-50">
                <div class="flex items-center justify-between flex-wrap gap-4">
                  <div class="flex items-center gap-4">
                    <div class="w-12 h-12 bg-red-100 rounded-2xl flex items-center justify-center">
                      <.icon name="hero-x-circle" class="w-6 h-6 text-red-600" />
                    </div>
                    <div>
                      <p class="text-red-800 font-extrabold">You didn't finish this challenge</p>
                      <p class="text-red-600 text-sm">
                        Don't give up! You can always try again.
                      </p>
                    </div>
                  </div>
                  <div class="flex gap-3">
                    <.link
                      navigate={~p"/challenges/#{@user_challenge_from_template.id}"}
                      class="inline-flex items-center gap-2 bg-red-100 text-red-700 px-5 py-3 rounded-2xl font-bold text-sm hover:bg-red-200 transition-colors"
                    >
                      View Past Attempt
                    </.link>
                    <button
                      phx-click="start_challenge"
                      class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-5 py-3 rounded-2xl font-bold text-sm hover:scale-105 transition-all"
                    >
                      <.icon name="hero-arrow-path" class="w-4 h-4" /> Start Again
                    </button>
                  </div>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% _ -> %>
          <% end %>
        <% end %>

        <%!-- Failed Challenge Banner --%>
        <%= if !@challenge.is_template && @challenge.status == :failed do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:md} class="mb-8 border-red-200 bg-red-50">
            <div class="flex items-start gap-4">
              <div class="w-12 h-12 bg-red-100 rounded-2xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-x-circle" class="w-6 h-6 text-red-600" />
              </div>
              <div>
                <p class="text-red-800 font-extrabold">This challenge has been marked as failed.</p>
                <%= if @challenge.failure_reason do %>
                  <p class="text-red-600 text-sm mt-1">Reason: {@challenge.failure_reason}</p>
                <% end %>
                <%= if @challenge.template_id do %>
                  <.link
                    navigate={~p"/challenges/#{@challenge.template_id}"}
                    class="inline-flex items-center gap-2 text-red-700 font-bold text-sm mt-3 hover:text-red-800 transition-colors"
                  >
                    <.icon name="hero-arrow-path" class="w-4 h-4" /> Start again from template
                  </.link>
                <% else %>
                  <.link
                    navigate={~p"/challenges/new"}
                    class="inline-flex items-center gap-2 text-red-700 font-bold text-sm mt-3 hover:text-red-800 transition-colors"
                  >
                    <.icon name="hero-arrow-path" class="w-4 h-4" /> Try Again
                  </.link>
                <% end %>
              </div>
            </div>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- About Section --%>
        <%= if @challenge.description do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <h2 class="text-2xl font-extrabold text-slate-900 mb-4">About this Challenge</h2>
            <p class="text-slate-600 whitespace-pre-wrap leading-relaxed">{@challenge.description}</p>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Progress Section --%>
        <%= if @participant && @progress && !@challenge.is_template do %>
          <HeadsUpWeb.Components.UI.Card.card
            padding={:lg}
            class={[
              "mb-8",
              if(@challenge.status == :failed, do: "opacity-75", else: "")
            ]}
          >
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Your Progress</h2>

            <%!-- Challenge Progress (by days) --%>
            <div class="mb-6">
              <div class="flex justify-between text-sm mb-2">
                <span class="font-bold text-slate-600">Challenge Progress</span>
                <span class="font-extrabold text-slate-900">
                  <%= if @challenge_started do %>
                    Day {@progress.days_elapsed} of {@progress.total_days}
                  <% else %>
                    Starts in {Date.diff(@participant.start_date, Date.utc_today())} days
                  <% end %>
                </span>
              </div>
              <div class="flex items-center gap-3">
                <div class={[
                  "flex-1 rounded-full h-3 overflow-hidden",
                  if(@challenge.status == :failed, do: "bg-slate-200", else: "bg-slate-100")
                ]}>
                  <div
                    class={[
                      "h-3 rounded-full transition-all duration-500",
                      if(@challenge.status == :failed, do: "bg-slate-400", else: "bg-indigo-500")
                    ]}
                    style={"width: #{@progress.days_percentage}%"}
                  >
                  </div>
                </div>
                <span class="font-extrabold text-sm text-slate-900 min-w-[3rem] text-right">
                  {Float.round(@progress.days_percentage * 1.0, 1)}%
                </span>
              </div>
              <%= if @progress.start_date && @progress.end_date do %>
                <p class="text-xs text-slate-400 mt-2">
                  {Calendar.strftime(@progress.start_date, "%b %d")} - {Calendar.strftime(
                    @progress.end_date,
                    "%b %d, %Y"
                  )}
                </p>
              <% end %>
            </div>

            <%!-- Mood Calendar --%>
            <%= if @mood_history != %{} do %>
              <div class="border-t border-slate-100 pt-6">
                <p class="text-sm font-bold text-slate-600 mb-4">Mood Tracker</p>
                <div class="flex flex-wrap gap-1.5">
                  <%= for day <- 1..@progress.total_days do %>
                    <.mood_day_tile
                      day={day}
                      mood={Map.get(@mood_history, day)}
                      days_elapsed={@progress.days_elapsed}
                    />
                  <% end %>
                </div>
                <div class="flex items-center gap-4 mt-3 text-xs text-slate-400">
                  <span class="flex items-center gap-1.5">
                    <.mood_icon mood="good" size="sm" /> Great
                  </span>
                  <span class="flex items-center gap-1.5">
                    <.mood_icon mood="neutral" size="sm" /> Okay
                  </span>
                  <span class="flex items-center gap-1.5">
                    <.mood_icon mood="upset" size="sm" /> Upset
                  </span>
                  <span class="flex items-center gap-1.5">
                    <.mood_icon mood={nil} size="sm" /> No mood
                  </span>
                </div>
              </div>
            <% end %>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Challenge Content (Phases/Steps or Tasks) — read-only reference --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
          <%= if @challenge.type == :predefined do %>
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Phases & Steps</h2>
            <%= if @challenge.phases == [] do %>
              <p class="text-slate-500">No phases defined yet.</p>
            <% else %>
              <div class="space-y-6">
                <%= for phase <- Enum.sort_by(@challenge.phases, & &1.order_index) do %>
                  <div class="bg-slate-50 rounded-2xl p-6 border border-slate-100">
                    <h3 class="font-extrabold text-slate-800 mb-3 text-lg">
                      Phase {phase.order_index + 1}: {phase.title}
                    </h3>
                    <%= if phase.description do %>
                      <p class="text-slate-500 text-sm mb-4">{phase.description}</p>
                    <% end %>
                    <div class="space-y-2">
                      <%= for step <- Enum.sort_by(phase.steps, & &1.order_index) do %>
                        <.step_item step={step} participant={nil} is_template={true} read_only={true} />
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% else %>
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Daily Tasks</h2>
            <%= if @challenge.tasks == [] do %>
              <p class="text-slate-500">No tasks defined yet.</p>
            <% else %>
              <div class="space-y-3">
                <%= for task <- @challenge.tasks do %>
                  <.task_item task={task} participant={nil} is_template={true} read_only={true} />
                <% end %>
              </div>
            <% end %>
          <% end %>
        </HeadsUpWeb.Components.UI.Card.card>

        <%!-- Missed Days Queue --%>
        <%= if @participant && !@challenge.is_template && @participant.status == :active && @challenge_started && length(@missed_days) > 0 do %>
          <% # Only show missed days that are NOT today (today has its own check-in section)
          past_missed = Enum.reject(@missed_days, &(Date.compare(&1, Date.utc_today()) == :eq)) %>
          <%= if length(past_missed) > 0 do %>
            <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
              <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
                  <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <h2 class="text-xl font-extrabold text-slate-900">Missed Check-ins</h2>
                  <p class="text-sm text-slate-500">
                    You have {length(past_missed)} missed day{if length(past_missed) != 1, do: "s"}. Check in to stay on track!
                    <%= if length(past_missed) >= 5 do %>
                      <span class="text-red-600 font-bold">
                        Warning: 7 consecutive missed days will fail your challenge.
                      </span>
                    <% end %>
                  </p>
                </div>
              </div>
              <div class="space-y-2">
                <%= for date <- Enum.take(past_missed, 10) do %>
                  <div class="flex items-center justify-between bg-amber-50 border border-amber-200 rounded-xl p-3">
                    <div class="flex items-center gap-3">
                      <.icon name="hero-calendar" class="w-5 h-5 text-amber-500" />
                      <span class="font-bold text-slate-700">
                        Day {Date.diff(date, @participant.start_date) + 1}
                      </span>
                      <span class="text-slate-500 text-sm">
                        {Calendar.strftime(date, "%b %d, %Y")}
                      </span>
                    </div>
                    <button
                      phx-click="check_in_missed_day"
                      phx-value-date={Date.to_iso8601(date)}
                      class="px-4 py-2 bg-amber-500 text-white rounded-xl text-sm font-bold hover:bg-amber-600 transition-colors"
                    >
                      Check In
                    </button>
                  </div>
                <% end %>
                <%= if length(past_missed) > 10 do %>
                  <p class="text-slate-500 text-sm text-center py-2">
                    And {length(past_missed) - 10} more missed days...
                  </p>
                <% end %>
              </div>
            </HeadsUpWeb.Components.UI.Card.card>
          <% end %>
        <% end %>

        <%!-- Today's Check-in --%>
        <%= if @participant && !@challenge.is_template && @participant.status == :active && @challenge_started do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Today's Check-in</h2>

            <%= if @has_checked_in do %>
              <div class="bg-green-50 border border-green-200 rounded-2xl p-6">
                <div class="flex items-center gap-4">
                  <div class="w-12 h-12 bg-green-100 rounded-2xl flex items-center justify-center">
                    <.icon name="hero-check-circle" class="w-6 h-6 text-green-600" />
                  </div>
                  <div>
                    <p class="text-green-800 font-extrabold">
                      Day {if(@progress, do: @progress.days_elapsed, else: 1)} completed!
                    </p>
                    <p class="text-green-600 text-sm">
                      Come back tomorrow to continue your challenge.
                    </p>
                  </div>
                </div>
              </div>
            <% else %>
              <%= if @today_items do %>
                <%= case @today_items do %>
                  <% {:steps, steps} -> %>
                    <%= if steps == [] do %>
                      <p class="text-slate-500">No steps defined yet.</p>
                    <% else %>
                      <p class="text-sm text-slate-500 mb-4">
                        Mark each step as done or failed, then finish the day.
                      </p>
                      <div class="space-y-3 mb-6">
                        <%= for step <- steps do %>
                          <div class={[
                            "flex items-center gap-4 p-4 rounded-2xl border transition-all",
                            case step.status do
                              :completed -> "bg-green-50 border-green-200"
                              :failed -> "bg-red-50 border-red-200"
                              _ -> "bg-slate-50 border-slate-100"
                            end
                          ]}>
                            <div class="flex-1">
                              <span class={[
                                "font-bold text-sm",
                                case step.status do
                                  :completed -> "text-green-700"
                                  :failed -> "text-red-700 line-through"
                                  _ -> "text-slate-700"
                                end
                              ]}>
                                {step.title}
                              </span>
                              <%= if step.description do %>
                                <p class="text-xs text-slate-400 mt-0.5">{step.description}</p>
                              <% end %>
                            </div>
                            <div class="flex gap-2">
                              <%= case step.status do %>
                                <% :completed -> %>
                                  <button
                                    phx-click="uncomplete_step"
                                    phx-value-step-id={step.id}
                                    class="px-4 py-2 bg-green-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-green-600 transition-colors"
                                  >
                                    <.icon name="hero-check" class="w-4 h-4" /> Done
                                  </button>
                                <% :failed -> %>
                                  <button
                                    phx-click="uncomplete_step"
                                    phx-value-step-id={step.id}
                                    class="px-4 py-2 bg-red-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-red-600 transition-colors"
                                  >
                                    <.icon name="hero-x-mark" class="w-4 h-4" /> Failed
                                  </button>
                                <% _ -> %>
                                  <button
                                    phx-click="complete_step"
                                    phx-value-step-id={step.id}
                                    class="px-4 py-2 bg-green-50 text-green-700 hover:bg-green-100 text-sm rounded-xl font-bold transition-colors"
                                  >
                                    Done
                                  </button>
                                  <button
                                    phx-click="fail_step"
                                    phx-value-step-id={step.id}
                                    class="px-4 py-2 bg-red-50 text-red-700 hover:bg-red-100 text-sm rounded-xl font-bold transition-colors"
                                  >
                                    Fail
                                  </button>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  <% {:tasks, tasks} -> %>
                    <%= if tasks == [] do %>
                      <p class="text-slate-500">No tasks scheduled for today. Enjoy your rest day!</p>
                    <% else %>
                      <p class="text-sm text-slate-500 mb-4">
                        Mark each task as done or failed, then finish the day.
                      </p>
                      <div class="space-y-3 mb-6">
                        <%= for task <- tasks do %>
                          <div class={[
                            "flex items-center gap-4 p-4 rounded-2xl border transition-all",
                            case task.status do
                              :accomplished -> "bg-green-50 border-green-200"
                              :failed -> "bg-red-50 border-red-200"
                              _ -> "bg-slate-50 border-slate-100"
                            end
                          ]}>
                            <div class="flex-1">
                              <span class={[
                                "font-bold text-sm",
                                case task.status do
                                  :accomplished -> "text-green-700"
                                  :failed -> "text-red-700 line-through"
                                  _ -> "text-slate-700"
                                end
                              ]}>
                                {task.title}
                              </span>
                              <%= if task.description do %>
                                <p class="text-xs text-slate-400 mt-0.5">{task.description}</p>
                              <% end %>
                            </div>
                            <div class="flex gap-2">
                              <%= case task.status do %>
                                <% :accomplished -> %>
                                  <button
                                    phx-click="uncomplete_task"
                                    phx-value-task-id={task.id}
                                    class="px-4 py-2 bg-green-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-green-600 transition-colors"
                                  >
                                    <.icon name="hero-check" class="w-4 h-4" /> Done
                                  </button>
                                <% :failed -> %>
                                  <button
                                    phx-click="uncomplete_task"
                                    phx-value-task-id={task.id}
                                    class="px-4 py-2 bg-red-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-red-600 transition-colors"
                                  >
                                    <.icon name="hero-x-mark" class="w-4 h-4" /> Failed
                                  </button>
                                <% _ -> %>
                                  <button
                                    phx-click="complete_task"
                                    phx-value-task-id={task.id}
                                    class="px-4 py-2 bg-green-50 text-green-700 hover:bg-green-100 text-sm rounded-xl font-bold transition-colors"
                                  >
                                    Done
                                  </button>
                                  <button
                                    phx-click="fail_task"
                                    phx-value-task-id={task.id}
                                    class="px-4 py-2 bg-red-50 text-red-700 hover:bg-red-100 text-sm rounded-xl font-bold transition-colors"
                                  >
                                    Fail
                                  </button>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                <% end %>
              <% end %>

              <%!-- Mood & Reflection & Finish Day --%>
              <div class="border-t border-slate-100 pt-6 mt-2">
                <%!-- Mood Selector --%>
                <label class="block text-sm font-bold text-slate-700 mb-3">
                  How are you feeling?
                </label>
                <div class="flex items-center gap-4 mb-6">
                  <button
                    type="button"
                    phx-click="select_mood"
                    phx-value-mood="upset"
                    class={[
                      "flex flex-col items-center gap-1.5 px-5 py-3 rounded-2xl border-2 transition-all min-w-[72px]",
                      if(@check_in_mood == "upset",
                        do: "bg-red-50 border-red-400 ring-2 ring-red-200 scale-105",
                        else: "bg-slate-50 border-slate-100 hover:bg-red-50 hover:border-red-200"
                      )
                    ]}
                  >
                    <.mood_icon mood="upset" size="xl" />
                    <span class={[
                      "text-xs font-bold",
                      if(@check_in_mood == "upset", do: "text-red-600", else: "text-slate-400")
                    ]}>
                      Upset
                    </span>
                  </button>
                  <button
                    type="button"
                    phx-click="select_mood"
                    phx-value-mood="neutral"
                    class={[
                      "flex flex-col items-center gap-1.5 px-5 py-3 rounded-2xl border-2 transition-all min-w-[72px]",
                      if(@check_in_mood == "neutral",
                        do: "bg-amber-50 border-amber-400 ring-2 ring-amber-200 scale-105",
                        else: "bg-slate-50 border-slate-100 hover:bg-amber-50 hover:border-amber-200"
                      )
                    ]}
                  >
                    <.mood_icon mood="neutral" size="xl" />
                    <span class={[
                      "text-xs font-bold",
                      if(@check_in_mood == "neutral", do: "text-amber-600", else: "text-slate-400")
                    ]}>
                      Okay
                    </span>
                  </button>
                  <button
                    type="button"
                    phx-click="select_mood"
                    phx-value-mood="good"
                    class={[
                      "flex flex-col items-center gap-1.5 px-5 py-3 rounded-2xl border-2 transition-all min-w-[72px]",
                      if(@check_in_mood == "good",
                        do: "bg-green-50 border-green-400 ring-2 ring-green-200 scale-105",
                        else: "bg-slate-50 border-slate-100 hover:bg-green-50 hover:border-green-200"
                      )
                    ]}
                  >
                    <.mood_icon mood="good" size="xl" />
                    <span class={[
                      "text-xs font-bold",
                      if(@check_in_mood == "good", do: "text-green-600", else: "text-slate-400")
                    ]}>
                      Great
                    </span>
                  </button>
                </div>

                <%!-- Daily Reflection --%>
                <label class="block text-sm font-bold text-slate-700 mb-3">
                  Daily Reflection (optional)
                </label>
                <textarea
                  phx-blur="update_check_in_note"
                  class="w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-800 focus:ring-2 focus:ring-blue-500/30 transition"
                  rows="3"
                  placeholder="How did today go? Any thoughts about your progress?"
                ><%= @check_in_note %></textarea>

                <button
                  phx-click="finish_day"
                  class="mt-4 w-full inline-flex items-center justify-center gap-2 bg-gradient-to-r from-green-500 to-emerald-600 text-white px-8 py-4 rounded-2xl font-bold text-base hover:scale-[1.02] transition-all"
                >
                  <.icon name="hero-check-circle" class="w-5 h-5" />
                  Finish Day {if(@progress, do: @progress.days_elapsed, else: 1)}
                </button>
              </div>
            <% end %>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Not Started Yet Banner --%>
        <%= if @participant && !@challenge.is_template && @participant.status == :active && !@challenge_started do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <div class="flex items-center gap-4">
              <div class="w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center">
                <.icon name="hero-calendar" class="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <p class="text-blue-800 font-extrabold">
                  Your challenge starts on {Calendar.strftime(@participant.start_date, "%B %d, %Y")}
                </p>
                <p class="text-blue-600 text-sm">
                  Come back in {Date.diff(@participant.start_date, Date.utc_today())} days to start tracking your progress!
                </p>
              </div>
            </div>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Challenge Feed --%>
        <%= if !@challenge.is_template && @feed != [] do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Challenge Feed</h2>
            <div class="space-y-4">
              <%= for check_in <- @feed do %>
                <.feed_item
                  check_in={check_in}
                  current_user_id={@current_user_id}
                  expanded_check_in_comments={@expanded_check_in_comments}
                />
              <% end %>
            </div>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>

        <%!-- Template: Challenge Statistics & People --%>
        <%= if @challenge.is_template do %>
          <%!-- Statistics Card --%>
          <%= if @template_stats.total > 0 do %>
            <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
              <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Challenge Statistics</h2>
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <div class="bg-slate-50 rounded-2xl p-5 text-center border border-slate-100">
                  <p class="text-3xl font-extrabold text-slate-900">{@template_stats.total}</p>
                  <p class="text-sm text-slate-500 font-bold mt-1">Started</p>
                </div>
                <div class="bg-green-50 rounded-2xl p-5 text-center border border-green-100">
                  <p class="text-3xl font-extrabold text-green-600">{@template_stats.completed}</p>
                  <p class="text-sm text-green-600 font-bold mt-1">Completed</p>
                </div>
                <div class="bg-red-50 rounded-2xl p-5 text-center border border-red-100">
                  <p class="text-3xl font-extrabold text-red-500">{@template_stats.failed}</p>
                  <p class="text-sm text-red-500 font-bold mt-1">Didn't Finish</p>
                </div>
                <div class="bg-blue-50 rounded-2xl p-5 text-center border border-blue-100">
                  <p class="text-3xl font-extrabold text-blue-600">
                    {if @template_stats.completed + @template_stats.failed > 0,
                      do: "#{@template_stats.success_rate}%",
                      else: "-"}
                  </p>
                  <p class="text-sm text-blue-600 font-bold mt-1">Success Rate</p>
                </div>
              </div>
            </HeadsUpWeb.Components.UI.Card.card>
          <% end %>

          <%!-- People Sections --%>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
            <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Community</h2>

            <%= if @template_starters == [] do %>
              <div class="text-center py-8">
                <div class="w-16 h-16 bg-slate-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <.icon name="hero-user-group" class="w-8 h-8 text-slate-400" />
                </div>
                <p class="text-slate-500 font-bold">No one has started this challenge yet.</p>
                <p class="text-slate-400 text-sm mt-1">Be the first!</p>
              </div>
            <% else %>
              <%!-- Currently Active --%>
              <%= if @grouped_starters.active != [] do %>
                <div class="mb-6">
                  <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-blue-500"></span>
                    Currently Active ({length(@grouped_starters.active)})
                  </h3>
                  <div class="flex flex-wrap gap-3">
                    <%= for starter <- @grouped_starters.active do %>
                      <div class="flex items-center gap-2 bg-blue-50 rounded-full px-4 py-2 border border-blue-100">
                        <HeadsUpWeb.Components.UI.Avatar.avatar
                          name={starter.user.name || starter.user.user_name || "U"}
                          src={starter.user.image_path}
                          size={:sm}
                        />
                        <span class="text-sm font-bold text-blue-700">
                          {starter.user.name || starter.user.user_name}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Completed --%>
              <%= if @grouped_starters.completed != [] do %>
                <div class="mb-6">
                  <h3 class="text-sm font-bold text-green-600 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-green-500"></span>
                    Completed ({length(@grouped_starters.completed)})
                  </h3>
                  <div class="flex flex-wrap gap-3">
                    <%= for starter <- @grouped_starters.completed do %>
                      <div class="flex items-center gap-2 bg-green-50 rounded-full px-4 py-2 border border-green-100">
                        <HeadsUpWeb.Components.UI.Avatar.avatar
                          name={starter.user.name || starter.user.user_name || "U"}
                          src={starter.user.image_path}
                          size={:sm}
                        />
                        <span class="text-sm font-bold text-green-700">
                          {starter.user.name || starter.user.user_name}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Didn't Finish --%>
              <%= if @grouped_starters.failed != [] do %>
                <div class="mb-6">
                  <h3 class="text-sm font-bold text-red-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-red-400"></span>
                    Didn't Finish ({length(@grouped_starters.failed)})
                  </h3>
                  <div class="flex flex-wrap gap-3">
                    <%= for starter <- @grouped_starters.failed do %>
                      <div class="flex items-center gap-2 bg-red-50 rounded-full px-4 py-2 border border-red-100">
                        <HeadsUpWeb.Components.UI.Avatar.avatar
                          name={starter.user.name || starter.user.user_name || "U"}
                          src={starter.user.image_path}
                          size={:sm}
                        />
                        <span class="text-sm font-bold text-red-600">
                          {starter.user.name || starter.user.user_name}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Challenge Info --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Challenge Info</h3>
          <div class="space-y-4">
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-bolt" class="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Type</p>
                <p class="text-slate-500 text-sm">
                  {if @challenge.type == :predefined,
                    do: "Official Challenge",
                    else: "Community Challenge"}
                </p>
              </div>
            </div>
            <%= if @challenge.duration_days do %>
              <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
                <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  <.icon name="hero-clock" class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p class="font-bold text-slate-900 text-sm">Duration</p>
                  <p class="text-slate-500 text-sm">{@challenge.duration_days} days</p>
                </div>
              </div>
            <% end %>
            <%= if !@challenge.is_template && @challenge.start_date && @challenge.end_date do %>
              <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
                <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  <.icon name="hero-calendar" class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p class="font-bold text-slate-900 text-sm">Schedule</p>
                  <p class="text-slate-500 text-sm">
                    {Calendar.strftime(@challenge.start_date, "%b %d")} - {Calendar.strftime(
                      @challenge.end_date,
                      "%b %d, %Y"
                    )}
                  </p>
                </div>
              </div>
            <% end %>
            <%= if @challenge.category do %>
              <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
                <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  <.icon name="hero-tag" class="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <p class="font-bold text-slate-900 text-sm">Category</p>
                  <p class="text-slate-500 text-sm">{@challenge.category.name}</p>
                </div>
              </div>
            <% end %>
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
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">All Challenges</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <%= if @current_user do %>
              <.link
                navigate={~p"/my-challenges"}
                class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
              >
                <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-folder" class="w-5 h-5 text-indigo-600" />
                </div>
                <span class="font-bold text-slate-700 group-hover:text-slate-900">My Challenges</span>
                <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
              </.link>
            <% end %>
          </div>
        </div>
      </aside>

      <%!-- ===== START/JOIN MODAL ===== --%>
      <%= if @show_join_modal do %>
        <div
          class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50"
          phx-click="close_join_modal"
        >
          <div
            class="bg-white rounded-[32px] soft-shadow max-w-md w-full mx-4 p-8"
            phx-click-away="close_join_modal"
          >
            <div class="flex justify-between items-center mb-6">
              <h3 class="text-2xl font-extrabold text-slate-900">
                {if @challenge.is_template, do: "Start Challenge", else: "Join Challenge"}
              </h3>
              <button
                phx-click="close_join_modal"
                class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-200 transition-colors"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <div class="mb-8">
              <% duration = calculate_challenge_duration(@challenge) %>
              <p class="text-slate-600 mb-6">
                This is a <strong class="text-slate-900"><%= duration %>-day challenge</strong>.
                Pick your start date and we'll calculate your end date automatically.
              </p>

              <label class="block text-sm font-bold text-slate-700 mb-2">
                When do you want to start?
              </label>
              <input
                type="date"
                value={@join_start_date}
                phx-blur="update_join_date"
                min={Date.to_iso8601(Date.utc_today())}
                class="w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-800 focus:ring-2 focus:ring-blue-500/30 transition"
              />

              <% end_date = Date.add(Date.from_iso8601!(@join_start_date), duration) %>
              <p class="text-sm text-slate-500 mt-3">
                Your challenge will end on:
                <strong class="text-slate-700">{Calendar.strftime(end_date, "%B %d, %Y")}</strong>
              </p>
            </div>

            <div class="flex gap-3">
              <button
                phx-click="close_join_modal"
                class="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-2xl font-bold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                phx-click={
                  if @challenge.is_template, do: "confirm_start_challenge", else: "confirm_join"
                }
                class={[
                  "flex-1 px-6 py-4 text-white rounded-2xl font-bold hover:scale-[1.02] transition-all",
                  if(@challenge.is_template,
                    do: "bg-gradient-to-r from-green-500 to-emerald-600",
                    else: "bg-gradient-to-r from-blue-500 to-indigo-600"
                  )
                ]}
              >
                {if @challenge.is_template, do: "Start Challenge", else: "Join Challenge"}
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- ===== FAIL MODAL ===== --%>
      <%= if @show_fail_modal do %>
        <div
          class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50"
          phx-click="close_fail_modal"
        >
          <div
            class="bg-white rounded-[32px] soft-shadow max-w-md w-full mx-4 p-8"
            phx-click-away="close_fail_modal"
          >
            <div class="flex justify-between items-center mb-6">
              <h3 class="text-2xl font-extrabold text-slate-900">Fail Challenge</h3>
              <button
                phx-click="close_fail_modal"
                class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-200 transition-colors"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <p class="text-slate-600 mb-6">
              Are you sure you want to fail this challenge? This cannot be undone, but
              <%= if @challenge.template_id do %>
                you can start again from the template.
              <% else %>
                you can create a new challenge to try again.
              <% end %>
            </p>

            <label class="block text-sm font-bold text-slate-700 mb-2">
              Reason (optional)
            </label>
            <textarea
              value={@failure_reason}
              phx-blur="update_failure_reason"
              class="w-full bg-slate-50 border-0 rounded-2xl px-5 py-4 text-slate-800 focus:ring-2 focus:ring-red-500/30 transition mb-6"
              rows="3"
              placeholder="What happened? Why did you decide to stop?"
            ></textarea>

            <div class="flex gap-3">
              <button
                phx-click="close_fail_modal"
                class="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-2xl font-bold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                phx-click="confirm_fail_challenge"
                class="flex-1 px-6 py-4 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-2xl font-bold hover:scale-[1.02] transition-all"
              >
                Fail Challenge
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Report Modal --%>
      <%= if @show_report_modal do %>
        <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div class="bg-white rounded-[32px] shadow-2xl max-w-md w-full p-8">
            <div class="flex items-center gap-3 mb-6">
              <div class="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-6 h-6 text-red-500" />
              </div>
              <h3 class="text-xl font-extrabold text-slate-900">Report Challenge</h3>
            </div>

            <p class="text-sm text-slate-500 mb-6">
              Help us keep the community safe. Select a reason for your report.
            </p>

            <form phx-submit="submit_report">
              <div class="mb-4">
                <label class="block text-sm font-bold text-slate-700 mb-3">Reason *</label>
                <div class="space-y-2">
                  <%= for reason <- HeadsUp.Reports.Report.reasons() do %>
                    <label class={"flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-colors #{if @report_reason == reason, do: "bg-red-50 ring-2 ring-red-200", else: "bg-slate-50 hover:bg-slate-100"}"}>
                      <input
                        type="radio"
                        name="report_reason"
                        value={reason}
                        checked={@report_reason == reason}
                        phx-click="update_report_reason"
                        phx-value-report_reason={reason}
                        class="text-red-500 focus:ring-red-500"
                      />
                      <span class="text-sm font-medium text-slate-700 capitalize">{reason}</span>
                    </label>
                  <% end %>
                </div>
              </div>

              <div class="mb-6">
                <label for="report_description" class="block text-sm font-bold text-slate-700 mb-2">
                  Additional details (optional)
                </label>
                <textarea
                  id="report_description"
                  name="report_description"
                  rows="3"
                  value={@report_description}
                  phx-change="update_report_description"
                  placeholder="Provide any additional context..."
                  maxlength="500"
                  class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-red-500 resize-none"
                ><%= @report_description %></textarea>
                <div class="text-xs text-slate-400 mt-1 text-right">
                  {String.length(@report_description)}/500
                </div>
              </div>

              <div class="flex justify-end gap-3">
                <button
                  type="button"
                  phx-click="hide_report_modal"
                  class="px-5 py-3 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold hover:bg-slate-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={@report_reason == ""}
                  class="px-5 py-3 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Submit Report
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Report Events
  # ============================================================================

  def handle_event("show_report_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_report_modal, true)
     |> assign(:report_reason, "")
     |> assign(:report_description, "")}
  end

  def handle_event("hide_report_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_report_modal, false)
     |> assign(:report_reason, "")
     |> assign(:report_description, "")}
  end

  def handle_event("update_report_reason", %{"report_reason" => reason}, socket) do
    {:noreply, assign(socket, :report_reason, reason)}
  end

  def handle_event("update_report_description", %{"report_description" => desc}, socket) do
    {:noreply, assign(socket, :report_description, desc)}
  end

  def handle_event("submit_report", _params, socket) do
    reason = socket.assigns.report_reason
    description = socket.assigns.report_description
    reporter_id = socket.assigns.current_user.id
    challenge_id = socket.assigns.challenge.id

    if reason == "" do
      {:noreply, put_flash(socket, :error, "Please select a reason for your report")}
    else
      attrs = %{reason: reason, description: description}

      case Reports.report_challenge(challenge_id, reporter_id, attrs) do
        {:ok, _report} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> assign(:report_reason, "")
           |> assign(:report_description, "")
           |> put_flash(:info, "Report submitted. Thank you for helping keep the community safe.")}

        {:error, :already_reported} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:info, "You have already reported this challenge.")}

        {:error, :cannot_report_own} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:error, "You cannot report your own challenge.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to submit report. Please try again.")}
      end
    end
  end

  # ============================================================================
  # Check-in Like & Comment Events
  # ============================================================================

  @impl true
  def handle_event("toggle_check_in_like", %{"check-in-id" => id}, socket) do
    {check_in_id, _} = Integer.parse(id)
    current_user_id = socket.assigns.current_user_id

    if current_user_id do
      was_liked =
        Map.get(
          Enum.find(socket.assigns.feed, &(&1.id == check_in_id)) || %{},
          :user_liked,
          false
        )

      case Challenges.react_to_check_in(check_in_id, current_user_id, "like") do
        {:ok, _} ->
          # react_to_check_in toggles: insert if no record, delete if same type, update if different type
          # After toggle, check if like still exists to determine new state
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

        {:error, :guest_not_allowed} ->
          {:noreply, put_flash(socket, :error, "You must be logged in to like posts")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to like check-in")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to like posts")}
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
    current_user_id = socket.assigns.current_user_id
    trimmed = String.trim(content)

    if trimmed == "" do
      {:noreply, put_flash(socket, :error, "Comment cannot be empty")}
    else
      case Challenges.create_check_in_comment(%{
             check_in_id: check_in_id,
             user_id: current_user_id,
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
  def handle_event("delete_check_in_comment", %{"comment-id" => cid, "check-in-id" => id}, socket) do
    {comment_id, _} = Integer.parse(cid)
    {check_in_id, _} = Integer.parse(id)
    comment = Challenges.get_check_in_comment!(comment_id)

    case Challenges.delete_check_in_comment(comment, socket.assigns.current_user_id) do
      {:ok, _} ->
        feed =
          update_check_in_in_feed(socket.assigns.feed, check_in_id, fn ci ->
            ci
            |> Map.put(:comments, Enum.reject(Map.get(ci, :comments, []), &(&1.id == comment_id)))
            |> Map.put(:comment_count, max(Map.get(ci, :comment_count, 0) - 1, 0))
          end)

        {:noreply, assign(socket, :feed, feed)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You cannot delete this comment")}
    end
  end

  defp update_check_in_in_feed(feed, check_in_id, update_fn) do
    Enum.map(feed, fn ci ->
      if ci.id == check_in_id, do: update_fn.(ci), else: ci
    end)
  end

  # ============================================================================
  # Components
  # ============================================================================

  defp feed_item(assigns) do
    ~H"""
    <div class="bg-slate-50 rounded-2xl p-5 border border-slate-100">
      <div class="flex items-start gap-4">
        <HeadsUpWeb.Components.UI.Avatar.avatar
          name={@check_in.user.name || @check_in.user.user_name || "U"}
          src={@check_in.user.image_path}
          size={:md}
        />
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-3">
            <%= if @check_in.mood do %>
              <.mood_icon mood={@check_in.mood} size="md" />
            <% end %>
            <span class="font-extrabold text-slate-900 text-sm">
              Day {@check_in.day_number}
            </span>
            <span class="text-xs text-slate-400">
              {Calendar.strftime(@check_in.completed_date, "%b %d, %Y")}
            </span>
          </div>

          <div class="flex flex-wrap gap-4 mb-2">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-green-500"></span>
              <span class="text-green-700 font-bold text-sm">{@check_in.completed_tasks} done</span>
            </div>
            <%= if @check_in.failed_tasks > 0 do %>
              <div class="flex items-center gap-2">
                <span class="w-3 h-3 rounded-full bg-red-500"></span>
                <span class="text-red-700 font-bold text-sm">{@check_in.failed_tasks} failed</span>
              </div>
            <% end %>
            <%= if @check_in.skipped_tasks > 0 do %>
              <div class="flex items-center gap-2">
                <span class="w-3 h-3 rounded-full bg-slate-400"></span>
                <span class="text-slate-500 font-bold text-sm">
                  {@check_in.skipped_tasks} skipped
                </span>
              </div>
            <% end %>
            <div class="flex items-center gap-2">
              <span class="text-slate-400 text-sm">of {@check_in.total_tasks} tasks</span>
            </div>
          </div>

          <%= if @check_in.note do %>
            <p class="text-slate-600 text-sm whitespace-pre-wrap">{@check_in.note}</p>
          <% end %>
        </div>
      </div>

      <%!-- Engagement bar --%>
      <div class="flex items-center gap-6 mt-4 pt-4 border-t border-slate-200">
        <%= if @current_user_id && @current_user_id != @check_in.user_id do %>
          <button
            phx-click="toggle_check_in_like"
            phx-value-check-in-id={@check_in.id}
            class={"flex items-center gap-1.5 text-sm font-bold transition-colors #{if Map.get(@check_in, :user_liked, false), do: "text-red-500", else: "text-slate-400 hover:text-red-500"}"}
          >
            <%= if Map.get(@check_in, :user_liked, false) do %>
              <.icon name="hero-heart-solid" class="w-5 h-5" />
            <% else %>
              <.icon name="hero-heart" class="w-5 h-5" />
            <% end %>
            {Map.get(@check_in, :like_count, 0)}
          </button>
        <% else %>
          <span class="flex items-center gap-1.5 text-sm font-bold text-slate-400">
            <.icon name="hero-heart" class="w-5 h-5" />
            {Map.get(@check_in, :like_count, 0)}
          </span>
        <% end %>

        <button
          phx-click="toggle_check_in_comments"
          phx-value-check-in-id={@check_in.id}
          class="flex items-center gap-1.5 text-sm font-bold text-slate-400 hover:text-blue-600 transition-colors"
        >
          <.icon name="hero-chat-bubble-left" class="w-5 h-5" />
          {Map.get(@check_in, :comment_count, 0)} comments
        </button>
      </div>

      <%!-- Comments section --%>
      <%= if MapSet.member?(@expanded_check_in_comments, @check_in.id) do %>
        <div class="mt-3 space-y-3 bg-white rounded-2xl p-4">
          <%= for comment <- Map.get(@check_in, :comments, []) do %>
            <div class="flex gap-3">
              <HeadsUpWeb.Components.UI.Avatar.avatar
                name={comment.user.name || comment.user.user_name || "U"}
                src={comment.user.image_path}
                size={:sm}
              />
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <span class="text-xs font-bold text-slate-900">
                    {comment.user.name || comment.user.user_name}
                  </span>
                  <div class="flex items-center gap-2">
                    <span class="text-xs text-slate-400">
                      {Calendar.strftime(comment.inserted_at, "%b %d")}
                    </span>
                    <%= if @current_user_id == comment.user_id do %>
                      <button
                        phx-click="delete_check_in_comment"
                        phx-value-comment-id={comment.id}
                        phx-value-check-in-id={@check_in.id}
                        class="text-slate-400 hover:text-red-600 transition-colors"
                        title="Delete comment"
                      >
                        <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                      </button>
                    <% end %>
                  </div>
                </div>
                <p class="text-sm text-slate-600 mt-1">{comment.content}</p>
              </div>
            </div>
          <% end %>
          <%= if Enum.empty?(Map.get(@check_in, :comments, [])) do %>
            <p class="text-xs text-slate-400 text-center py-3">No comments yet</p>
          <% end %>
        </div>

        <%= if @current_user_id do %>
          <form phx-submit="add_check_in_comment" class="flex gap-2 mt-2">
            <input type="hidden" name="check-in-id" value={@check_in.id} />
            <input
              type="text"
              name="content"
              placeholder="Write a comment..."
              maxlength="500"
              required
              class="flex-1 bg-white border border-slate-200 rounded-xl px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <button
              type="submit"
              class="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-xs font-bold"
            >
              Post
            </button>
          </form>
        <% else %>
          <p class="text-xs text-slate-400 text-center mt-2">Log in to comment</p>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp step_item(assigns) do
    read_only = Map.get(assigns, :read_only, false)

    status =
      if assigns.participant && !assigns.is_template do
        get_step_status_for_display(assigns.participant.id, assigns.step.id)
      else
        :pending
      end

    assigns = assigns |> assign(:status, status) |> assign(:read_only, read_only)

    ~H"""
    <div class={[
      "flex items-center gap-3 p-3 rounded-xl transition-all",
      case @status do
        :completed -> "bg-green-50 border border-green-200"
        :failed -> "bg-red-50 border border-red-200"
        _ -> "bg-white border border-slate-100"
      end
    ]}>
      <%= if @participant && !@is_template && !@read_only do %>
        <%= case @status do %>
          <% :completed -> %>
            <button
              phx-click="uncomplete_step"
              phx-value-step-id={@step.id}
              class="w-7 h-7 rounded-full bg-green-500 flex items-center justify-center text-white hover:bg-green-600 transition-colors"
            >
              <.icon name="hero-check" class="w-4 h-4" />
            </button>
          <% :failed -> %>
            <button
              phx-click="uncomplete_step"
              phx-value-step-id={@step.id}
              class="w-7 h-7 rounded-full bg-red-500 flex items-center justify-center text-white hover:bg-red-600 transition-colors"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          <% _ -> %>
            <button
              phx-click="complete_step"
              phx-value-step-id={@step.id}
              class="w-7 h-7 rounded-full border-2 border-slate-300 hover:border-blue-500 transition-colors"
            >
            </button>
        <% end %>
      <% else %>
        <%= case @status do %>
          <% :completed -> %>
            <div class="w-7 h-7 rounded-full bg-green-500 flex items-center justify-center text-white">
              <.icon name="hero-check" class="w-4 h-4" />
            </div>
          <% :failed -> %>
            <div class="w-7 h-7 rounded-full bg-red-500 flex items-center justify-center text-white">
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </div>
          <% _ -> %>
            <div class="w-7 h-7 rounded-full border-2 border-slate-200"></div>
        <% end %>
      <% end %>
      <div class="flex-1">
        <span class={[
          "text-sm font-bold",
          case @status do
            :completed -> "text-green-700 line-through"
            :failed -> "text-red-700 line-through"
            _ -> "text-slate-700"
          end
        ]}>
          {@step.title}
        </span>
        <%= if @step.description do %>
          <p class="text-xs text-slate-400">{@step.description}</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp task_item(assigns) do
    read_only = Map.get(assigns, :read_only, false)

    status =
      if assigns.participant && !assigns.is_template do
        get_task_status_today(assigns.participant.id, assigns.task.id)
      else
        :pending
      end

    assigns = assigns |> assign(:status, status) |> assign(:read_only, read_only)

    ~H"""
    <div class={[
      "flex items-center gap-4 p-4 rounded-2xl border transition-all",
      if @is_template do
        "bg-slate-50 border-slate-100"
      else
        case @status do
          :accomplished -> "bg-green-50 border-green-200"
          :failed -> "bg-red-50 border-red-200"
          _ -> "bg-slate-50 border-slate-100"
        end
      end
    ]}>
      <%!-- Status indicator (read-only mode) --%>
      <%= if @participant && !@is_template && @read_only do %>
        <%= case @status do %>
          <% :accomplished -> %>
            <div class="w-7 h-7 rounded-full bg-green-500 flex items-center justify-center text-white flex-shrink-0">
              <.icon name="hero-check" class="w-4 h-4" />
            </div>
          <% :failed -> %>
            <div class="w-7 h-7 rounded-full bg-red-500 flex items-center justify-center text-white flex-shrink-0">
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </div>
          <% _ -> %>
            <div class="w-7 h-7 rounded-full border-2 border-slate-200 flex-shrink-0"></div>
        <% end %>
      <% end %>

      <div class="flex-1">
        <span class={[
          "font-bold text-sm",
          if @is_template do
            "text-slate-700"
          else
            case @status do
              :accomplished -> "text-green-700"
              :failed -> "text-red-700 line-through"
              _ -> "text-slate-700"
            end
          end
        ]}>
          {@task.title}
        </span>
        <span class="text-xs text-slate-400 ml-2">
          ({schedule_label(@task.schedule_type)})
        </span>
        <%= if @task.description do %>
          <p class="text-xs text-slate-400 mt-1">{@task.description}</p>
        <% end %>
      </div>

      <%= if @participant && !@is_template && !@read_only do %>
        <div class="flex gap-2">
          <%= case @status do %>
            <% :accomplished -> %>
              <button
                phx-click="uncomplete_task"
                phx-value-task-id={@task.id}
                class="px-4 py-2 bg-green-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-green-600 transition-colors"
              >
                <.icon name="hero-check" class="w-4 h-4" /> Done
              </button>
            <% :failed -> %>
              <button
                phx-click="uncomplete_task"
                phx-value-task-id={@task.id}
                class="px-4 py-2 bg-red-500 text-white text-sm rounded-xl font-bold flex items-center gap-1.5 hover:bg-red-600 transition-colors"
              >
                <.icon name="hero-x-mark" class="w-4 h-4" /> Failed
              </button>
            <% _ -> %>
              <button
                phx-click="complete_task"
                phx-value-task-id={@task.id}
                class="px-4 py-2 bg-green-50 text-green-700 hover:bg-green-100 text-sm rounded-xl font-bold transition-colors"
              >
                Done
              </button>
              <button
                phx-click="fail_task"
                phx-value-task-id={@task.id}
                class="px-4 py-2 bg-red-50 text-red-700 hover:bg-red-100 text-sm rounded-xl font-bold transition-colors"
              >
                Fail
              </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  defp get_step_status_for_display(participant_id, step_id) do
    Challenges.get_step_status(participant_id, step_id)
  end

  defp get_task_status_today(participant_id, task_id) do
    Challenges.get_task_status(participant_id, task_id, Date.utc_today())
  end

  defp schedule_label(:daily), do: "Daily"
  defp schedule_label(:twice_week), do: "Twice a week"
  defp schedule_label(:every_other_day), do: "Every other day"
  defp schedule_label(:mon_fri), do: "Mon-Fri"
  defp schedule_label(:custom_weekdays), do: "Custom days"

  defp calculate_challenge_duration(challenge) do
    cond do
      challenge.duration_days ->
        challenge.duration_days

      challenge.start_date && challenge.end_date ->
        Date.diff(challenge.end_date, challenge.start_date)

      true ->
        30
    end
  end

  defp mood_day_tile(assigns) do
    mood = assigns.mood
    day = assigns.day
    is_future = day > assigns.days_elapsed

    bg_class =
      cond do
        is_future -> "bg-slate-50 border border-dashed border-slate-200"
        mood == "good" -> "bg-green-50 border border-green-200"
        mood == "neutral" -> "bg-amber-50 border border-amber-200"
        mood == "upset" -> "bg-red-50 border border-red-200"
        true -> "bg-slate-100 border border-slate-200"
      end

    assigns =
      assign(assigns, :bg_class, bg_class)
      |> assign(:is_future, is_future)

    ~H"""
    <div
      class={["w-9 h-9 rounded-xl flex items-center justify-center transition-all", @bg_class]}
      title={"Day #{@day}"}
    >
      <%= if @mood in ["good", "neutral", "upset"] do %>
        <.mood_icon mood={@mood} size="sm" />
      <% else %>
        <%= if @is_future do %>
          <span class="text-xs text-slate-300">{@day}</span>
        <% else %>
          <span class="text-xs text-slate-400">{@day}</span>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc false
  defp mood_icon(%{mood: "good"} = assigns) do
    size_class = mood_size_class(assigns[:size])
    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg class={@size_class} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#dcfce7" stroke="#22c55e" stroke-width="1.5" />
      <circle cx="9" cy="10" r="1.2" fill="#16a34a" />
      <circle cx="15" cy="10" r="1.2" fill="#16a34a" />
      <path
        d="M8 14.5c1.2 1.8 2.8 2.5 4 2.5s2.8-.7 4-2.5"
        stroke="#16a34a"
        stroke-width="1.5"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  defp mood_icon(%{mood: "neutral"} = assigns) do
    size_class = mood_size_class(assigns[:size])
    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg class={@size_class} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#fef9c3" stroke="#eab308" stroke-width="1.5" />
      <circle cx="9" cy="10" r="1.2" fill="#a16207" />
      <circle cx="15" cy="10" r="1.2" fill="#a16207" />
      <line
        x1="8.5"
        y1="15"
        x2="15.5"
        y2="15"
        stroke="#a16207"
        stroke-width="1.5"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  defp mood_icon(%{mood: "upset"} = assigns) do
    size_class = mood_size_class(assigns[:size])
    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg class={@size_class} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#fee2e2" stroke="#ef4444" stroke-width="1.5" />
      <circle cx="9" cy="10" r="1.2" fill="#b91c1c" />
      <circle cx="15" cy="10" r="1.2" fill="#b91c1c" />
      <path
        d="M8 16.5c1.2-1.8 2.8-2.5 4-2.5s2.8.7 4 2.5"
        stroke="#b91c1c"
        stroke-width="1.5"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  defp mood_icon(assigns) do
    size_class = mood_size_class(assigns[:size])
    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg class={@size_class} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#f1f5f9" stroke="#cbd5e1" stroke-width="1.5" />
    </svg>
    """
  end

  defp mood_size_class("sm"), do: "w-5 h-5"
  defp mood_size_class("md"), do: "w-6 h-6"
  defp mood_size_class("lg"), do: "w-8 h-8"
  defp mood_size_class("xl"), do: "w-10 h-10"
  defp mood_size_class(_), do: "w-6 h-6"
end
