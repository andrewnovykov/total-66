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

        # Redirect active participants to the dedicated active challenge page
        if participant && !challenge.is_template do
          {:ok, push_navigate(socket, to: ~p"/my-challenges/#{challenge.id}")}
        else
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

          socket =
            socket
            |> assign(:challenge, challenge)
            |> assign(:page_title, challenge.title)
            |> assign(:show_join_modal, false)
            |> assign(:join_start_date, Date.to_iso8601(Date.utc_today()))
            |> assign(:user_challenge_from_template, user_challenge_from_template)
            |> assign(:template_starters, template_starters)
            |> assign(:grouped_starters, grouped_starters)
            |> assign(:template_stats, template_stats)
            |> assign(:current_user_id, if(current_user, do: current_user.id, else: nil))
            |> assign(:show_report_modal, false)
            |> assign(:report_reason, "")
            |> assign(:report_description, "")

          {:ok, socket, layout: {HeadsUpWeb.Layouts, :public}}
        end
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

    if challenge.type == :official do
      {:noreply, assign(socket, :show_join_modal, true)}
    else
      {:noreply, assign(socket, :show_join_modal, true)}
    end
  end

  @impl true
  def handle_event("close_join_modal", _params, socket) do
    {:noreply, assign(socket, :show_join_modal, false)}
  end

  @impl true
  def handle_event("update_join_date", %{"value" => date_str}, socket) do
    {:noreply, assign(socket, :join_start_date, date_str)}
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
         |> push_navigate(to: ~p"/my-challenges/#{new_challenge.id}")}

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

  @impl true
  def handle_event("confirm_join", _params, socket) do
    challenge = socket.assigns.challenge
    current_user = socket.assigns.current_user

    start_date =
      case Date.from_iso8601(socket.assigns.join_start_date) do
        {:ok, date} -> date
        _ -> Date.utc_today()
      end

    case Challenges.join_challenge(challenge.id, current_user.id, start_date: start_date) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:info, "Successfully joined the challenge!")
         |> push_navigate(to: ~p"/my-challenges/#{challenge.id}")}

      {:error, :already_joined} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:error, "You've already joined this challenge.")}

      {:error, :active_limit_reached} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:error, "You've reached the maximum of 3 active goals/challenges.")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_join_modal, false)
         |> put_flash(:error, "Could not join challenge.")}
    end
  end

  # ============================================================================
  # Delete / Share Events
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
  # Render
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Page Header --%>
    <div class="pt-[60px] pb-[40px] sm:pb-[60px] px-5 sm:px-10 max-w-[900px] mx-auto relative bg-[#0a0a0a]">
      <%!-- Watermark --%>
      <div class="absolute top-[80px] left-5 sm:left-10 font-display text-[clamp(80px,15vw,240px)] text-[rgba(255,77,0,0.03)] pointer-events-none leading-none tracking-[10px] select-none">
        CHALLENGE
      </div>

      <%!-- Back link --%>
      <.link
        navigate={~p"/challenges"}
        class="inline-flex items-center gap-2 text-t66-text-muted hover:text-t66-text-secondary text-sm font-medium mb-6 transition-colors relative"
      >
        <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Challenges
      </.link>

      <%!-- Badges --%>
      <div class="flex flex-wrap items-center gap-2 mb-4 relative">
        <%= if @challenge.is_template do %>
          <span class="px-3 py-1 text-[0.6rem] font-bold rounded-full uppercase tracking-[1.5px] bg-[rgba(255,198,66,0.12)] text-t66-gold">
            Template
          </span>
        <% end %>
        <span class={[
          "px-3 py-1 text-[0.6rem] font-bold rounded-full uppercase tracking-[1.5px]",
          if(@challenge.type == :official,
            do: "bg-[rgba(255,77,0,0.15)] text-t66-accent",
            else: "bg-[rgba(0,212,170,0.12)] text-t66-cyan"
          )
        ]}>
          {if @challenge.type == :official, do: "Official", else: "Community"}
        </span>
        <span class="px-3 py-1 text-[0.6rem] font-bold rounded-full uppercase tracking-[1.5px] bg-[rgba(255,255,255,0.04)] text-t66-text-muted">
          {Phoenix.Naming.humanize(@challenge.visibility)}
        </span>
      </div>

      <%!-- Title --%>
      <h1 class="font-display text-[clamp(2.2rem,5vw,3.4rem)] tracking-[3px] leading-[1.1] mb-3 text-[#f0ece6] relative">
        {@challenge.title}
      </h1>

      <%!-- Creator --%>
      <%= if @challenge.creator do %>
        <p class="text-t66-text-secondary text-[0.95rem] mb-4 relative">
          Created by <span class="text-[#f0ece6] font-bold">{@challenge.creator.name || @challenge.creator.user_name}</span>
        </p>
      <% end %>

      <%!-- Meta Row --%>
      <div class="flex flex-wrap items-center gap-4 text-t66-text-secondary text-[0.85rem] relative">
        <%= if @challenge.duration_days do %>
          <span class="flex items-center gap-1.5">
            <.icon name="hero-clock" class="w-4 h-4 text-t66-accent" />
            {@challenge.duration_days} Day Challenge
          </span>
        <% end %>
        <%= if @challenge.is_template do %>
          <span class="flex items-center gap-1.5">
            <.icon name="hero-user-group" class="w-4 h-4 text-t66-purple" />
            {@template_stats.total} started
          </span>
          <%= if @template_stats.completed > 0 do %>
            <span class="flex items-center gap-1.5">
              <.icon name="hero-trophy" class="w-4 h-4 text-t66-gold" />
              {@template_stats.success_rate}% success rate
            </span>
          <% end %>
        <% end %>
      </div>
    </div>

    <%!-- Main Content --%>
    <div class="max-w-[900px] mx-auto px-5 sm:px-10 pb-20">

      <%!-- Action Buttons --%>
      <%= if @current_user do %>
        <div class="flex flex-wrap gap-3 mb-8">
          <%= if @challenge.is_template do %>
            <%= if @user_challenge_from_template && @user_challenge_from_template.status in [:active, :paused] do %>
              <.link
                navigate={~p"/my-challenges/#{@user_challenge_from_template.id}"}
                class="inline-flex items-center gap-2 bg-t66-accent text-white px-6 py-3.5 rounded-xl font-bold text-[0.85rem] tracking-[1px] uppercase hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)]"
              >
                <.icon name="hero-eye" class="w-5 h-5" /> View My Challenge
              </.link>
            <% else %>
              <button
                phx-click="start_challenge"
                class="inline-flex items-center gap-2 bg-t66-accent text-white px-6 py-3.5 rounded-xl font-bold text-[0.85rem] tracking-[1px] uppercase hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)]"
              >
                <.icon name="hero-play" class="w-5 h-5" />
                {if @user_challenge_from_template, do: "Start Again", else: "Start Challenge"}
              </button>
            <% end %>
          <% end %>
          <%= if @challenge.creator_user_id == @current_user.id || @current_user.role in [:admin, "admin"] do %>
            <button
              phx-click="delete_challenge"
              data-confirm="Are you sure you want to delete this challenge? This action cannot be undone."
              class="inline-flex items-center gap-2 bg-[rgba(239,68,68,0.12)] text-[#ef4444] border border-[rgba(239,68,68,0.2)] px-5 py-3 rounded-xl font-bold text-[0.8rem] tracking-[1px] uppercase hover:bg-[rgba(239,68,68,0.2)] transition-all"
            >
              <.icon name="hero-trash" class="w-4 h-4" /> Delete
            </button>
          <% end %>
          <%= if @challenge.creator_user_id != @current_user.id do %>
            <button
              phx-click="show_report_modal"
              class="inline-flex items-center gap-2 bg-[rgba(255,255,255,0.04)] text-t66-text-muted border border-[rgba(255,255,255,0.06)] px-5 py-3 rounded-xl font-bold text-[0.8rem] tracking-[1px] uppercase hover:border-[rgba(239,68,68,0.3)] hover:text-[#ef4444] transition-all"
              title="Report challenge"
            >
              <.icon name="hero-flag" class="w-4 h-4" /> Report
            </button>
          <% end %>
        </div>
      <% end %>

      <%!-- Template Status Banner --%>
      <%= if @challenge.is_template && @user_challenge_from_template do %>
        <%= case @user_challenge_from_template.status do %>
          <% status when status in [:active, :paused] -> %>
            <div class="bg-t66-card border border-[rgba(34,197,94,0.2)] rounded-2xl p-5 mb-6">
              <div class="flex items-center justify-between flex-wrap gap-4">
                <div class="flex items-center gap-4">
                  <div class="w-11 h-11 bg-[rgba(34,197,94,0.12)] rounded-xl flex items-center justify-center">
                    <.icon name="hero-check-circle" class="w-5 h-5 text-[#22c55e]" />
                  </div>
                  <div>
                    <p class="text-[#22c55e] font-bold text-[0.9rem]">You've already started this challenge!</p>
                    <p class="text-t66-text-muted text-[0.8rem]">
                      Started on {Calendar.strftime(@user_challenge_from_template.start_date, "%b %d, %Y")}
                    </p>
                  </div>
                </div>
                <.link
                  navigate={~p"/my-challenges/#{@user_challenge_from_template.id}"}
                  class="inline-flex items-center gap-2 bg-[rgba(34,197,94,0.15)] text-[#22c55e] px-5 py-2.5 rounded-xl font-bold text-[0.8rem] hover:bg-[rgba(34,197,94,0.25)] transition-all"
                >
                  Go to My Challenge <.icon name="hero-chevron-right" class="w-4 h-4" />
                </.link>
              </div>
            </div>
          <% :completed -> %>
            <div class="bg-t66-card border border-[rgba(255,198,66,0.2)] rounded-2xl p-5 mb-6">
              <div class="flex items-center justify-between flex-wrap gap-4">
                <div class="flex items-center gap-4">
                  <div class="w-11 h-11 bg-[rgba(255,198,66,0.12)] rounded-xl flex items-center justify-center">
                    <.icon name="hero-trophy" class="w-5 h-5 text-t66-gold" />
                  </div>
                  <div>
                    <p class="text-t66-gold font-bold text-[0.9rem]">You completed this challenge!</p>
                    <p class="text-t66-text-muted text-[0.8rem]">Great work! You can start it again if you'd like.</p>
                  </div>
                </div>
                <.link
                  navigate={~p"/my-challenges/#{@user_challenge_from_template.id}"}
                  class="inline-flex items-center gap-2 bg-[rgba(255,198,66,0.12)] text-t66-gold px-5 py-2.5 rounded-xl font-bold text-[0.8rem] hover:bg-[rgba(255,198,66,0.2)] transition-all"
                >
                  View My Challenge <.icon name="hero-chevron-right" class="w-4 h-4" />
                </.link>
              </div>
            </div>
          <% status when status in [:failed, :cancelled] -> %>
            <div class="bg-t66-card border border-[rgba(239,68,68,0.2)] rounded-2xl p-5 mb-6">
              <div class="flex items-center justify-between flex-wrap gap-4">
                <div class="flex items-center gap-4">
                  <div class="w-11 h-11 bg-[rgba(239,68,68,0.12)] rounded-xl flex items-center justify-center">
                    <.icon name="hero-x-circle" class="w-5 h-5 text-[#ef4444]" />
                  </div>
                  <div>
                    <p class="text-[#ef4444] font-bold text-[0.9rem]">You didn't finish this challenge</p>
                    <p class="text-t66-text-muted text-[0.8rem]">Don't give up! You can always try again.</p>
                  </div>
                </div>
                <div class="flex gap-3">
                  <.link
                    navigate={~p"/my-challenges/#{@user_challenge_from_template.id}"}
                    class="inline-flex items-center gap-2 bg-[rgba(239,68,68,0.12)] text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-[0.8rem] hover:bg-[rgba(239,68,68,0.2)] transition-all"
                  >
                    View Past Attempt
                  </.link>
                  <button
                    phx-click="start_challenge"
                    class="inline-flex items-center gap-2 bg-t66-accent text-white px-5 py-2.5 rounded-xl font-bold text-[0.8rem] hover:-translate-y-0.5 transition-all shadow-[0_0_20px_rgba(255,77,0,0.15)]"
                  >
                    <.icon name="hero-arrow-path" class="w-4 h-4" /> Start Again
                  </button>
                </div>
              </div>
            </div>
          <% _ -> %>
        <% end %>
      <% end %>

      <%!-- About Section --%>
      <%= if @challenge.description do %>
        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7 mb-6">
          <h2 class="font-display text-[1.4rem] tracking-[2px] text-[#f0ece6] mb-4">
            About this Challenge
          </h2>
          <p class="text-t66-text-secondary text-[0.9rem] whitespace-pre-wrap leading-relaxed">
            {@challenge.description}
          </p>
        </div>
      <% end %>

      <%!-- Daily Tasks --%>
      <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7 mb-6">
        <h2 class="font-display text-[1.4rem] tracking-[2px] text-[#f0ece6] mb-1">
          Daily Tasks
        </h2>
        <p class="text-t66-text-muted text-[0.8rem] mb-5">
          Tasks you'll complete each day during this challenge
        </p>
        <%= if @challenge.tasks == [] do %>
          <p class="text-t66-text-muted text-[0.85rem]">No tasks defined yet.</p>
        <% else %>
          <div class="flex flex-col gap-2">
            <%= for task <- @challenge.tasks do %>
              <div class="flex items-center gap-3 p-4 bg-[#0a0a0a] border border-[rgba(255,255,255,0.06)] rounded-xl">
                <div class="w-[22px] h-[22px] rounded-[6px] border-2 border-[rgba(255,255,255,0.08)] flex-shrink-0"></div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <span class="text-[0.88rem] font-semibold text-[#f0ece6]">{task.title}</span>
                    <span class={[
                      "text-[0.55rem] uppercase tracking-[1.5px] px-[7px] py-[2px] rounded font-bold",
                      if(task.task_type == :mandatory,
                        do: "text-t66-accent bg-[rgba(255,77,0,0.15)]",
                        else: "text-t66-text-muted bg-[rgba(255,255,255,0.04)]"
                      )
                    ]}>
                      {if task.task_type == :mandatory, do: "Required", else: "Optional"}
                    </span>
                  </div>
                  <div class="flex items-center gap-1.5 mt-1">
                    <span class="text-[0.7rem] text-t66-text-muted">{schedule_label(task.schedule_type)}</span>
                  </div>
                  <%= if task.description do %>
                    <p class="text-[0.75rem] text-t66-text-muted mt-1">{task.description}</p>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Challenge Statistics --%>
      <%= if @challenge.is_template && @template_stats.total > 0 do %>
        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7 mb-6">
          <h2 class="font-display text-[1.4rem] tracking-[2px] text-[#f0ece6] mb-5">
            Challenge Statistics
          </h2>
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div class="bg-[#0a0a0a] border border-[rgba(255,255,255,0.06)] rounded-xl p-5 text-center">
              <p class="font-display text-[2rem] text-t66-accent leading-none">{@template_stats.total}</p>
              <p class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Started</p>
            </div>
            <div class="bg-[#0a0a0a] border border-[rgba(255,255,255,0.06)] rounded-xl p-5 text-center">
              <p class="font-display text-[2rem] text-[#22c55e] leading-none">{@template_stats.completed}</p>
              <p class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Completed</p>
            </div>
            <div class="bg-[#0a0a0a] border border-[rgba(255,255,255,0.06)] rounded-xl p-5 text-center">
              <p class="font-display text-[2rem] text-[#ef4444] leading-none">{@template_stats.failed}</p>
              <p class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Didn't Finish</p>
            </div>
            <div class="bg-[#0a0a0a] border border-[rgba(255,255,255,0.06)] rounded-xl p-5 text-center">
              <p class="font-display text-[2rem] text-t66-gold leading-none">
                {if @template_stats.completed + @template_stats.failed > 0,
                  do: "#{@template_stats.success_rate}%",
                  else: "-"}
              </p>
              <p class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Success Rate</p>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Community Section --%>
      <%= if @challenge.is_template do %>
        <div class="bg-t66-card border border-[rgba(255,255,255,0.06)] rounded-2xl p-7 mb-6">
          <h2 class="font-display text-[1.4rem] tracking-[2px] text-[#f0ece6] mb-5">
            Community
          </h2>

          <%= if @template_starters == [] do %>
            <div class="text-center py-8">
              <div class="w-14 h-14 bg-[rgba(255,255,255,0.04)] rounded-2xl flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-user-group" class="w-7 h-7 text-t66-text-muted" />
              </div>
              <p class="text-t66-text-secondary font-bold">No one has started this challenge yet.</p>
              <p class="text-t66-text-muted text-sm mt-1">Be the first!</p>
            </div>
          <% else %>
            <%!-- Currently Active --%>
            <%= if @grouped_starters.active != [] do %>
              <div class="mb-6">
                <h3 class="text-[0.7rem] font-bold text-[#3b82f6] uppercase tracking-[2px] mb-3 flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-[#3b82f6]"></span>
                  Currently Active ({length(@grouped_starters.active)})
                </h3>
                <div class="flex flex-wrap gap-2">
                  <%= for starter <- @grouped_starters.active do %>
                    <div class="flex items-center gap-2 bg-[rgba(59,130,246,0.08)] rounded-full px-4 py-2 border border-[rgba(59,130,246,0.15)]">
                      <HeadsUpWeb.Components.UI.Avatar.avatar
                        name={starter.user.name || starter.user.user_name || "U"}
                        src={starter.user.image_path}
                        size={:sm}
                      />
                      <span class="text-sm font-bold text-[#93c5fd]">
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
                <h3 class="text-[0.7rem] font-bold text-[#22c55e] uppercase tracking-[2px] mb-3 flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-[#22c55e]"></span>
                  Completed ({length(@grouped_starters.completed)})
                </h3>
                <div class="flex flex-wrap gap-2">
                  <%= for starter <- @grouped_starters.completed do %>
                    <div class="flex items-center gap-2 bg-[rgba(34,197,94,0.08)] rounded-full px-4 py-2 border border-[rgba(34,197,94,0.15)]">
                      <HeadsUpWeb.Components.UI.Avatar.avatar
                        name={starter.user.name || starter.user.user_name || "U"}
                        src={starter.user.image_path}
                        size={:sm}
                      />
                      <span class="text-sm font-bold text-[#86efac]">
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
                <h3 class="text-[0.7rem] font-bold text-[#ef4444] uppercase tracking-[2px] mb-3 flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-[#ef4444]"></span>
                  Didn't Finish ({length(@grouped_starters.failed)})
                </h3>
                <div class="flex flex-wrap gap-2">
                  <%= for starter <- @grouped_starters.failed do %>
                    <div class="flex items-center gap-2 bg-[rgba(239,68,68,0.08)] rounded-full px-4 py-2 border border-[rgba(239,68,68,0.15)]">
                      <HeadsUpWeb.Components.UI.Avatar.avatar
                        name={starter.user.name || starter.user.user_name || "U"}
                        src={starter.user.image_path}
                        size={:sm}
                      />
                      <span class="text-sm font-bold text-[#fca5a5]">
                        {starter.user.name || starter.user.user_name}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>

    <%!-- ===== START/JOIN MODAL ===== --%>
    <%= if @show_join_modal do %>
      <div
        class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
        phx-click="close_join_modal"
      >
        <div
          class="bg-t66-card border border-[rgba(255,255,255,0.08)] rounded-2xl max-w-md w-full mx-4 p-8"
          phx-click-away="close_join_modal"
        >
          <div class="flex justify-between items-center mb-6">
            <h3 class="font-display text-[1.6rem] tracking-[2px] text-[#f0ece6]">
              {if @challenge.is_template, do: "Start Challenge", else: "Join Challenge"}
            </h3>
            <button
              phx-click="close_join_modal"
              class="w-10 h-10 bg-[rgba(255,255,255,0.04)] rounded-xl flex items-center justify-center text-t66-text-muted hover:text-[#f0ece6] hover:bg-[rgba(255,255,255,0.08)] transition-all"
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>

          <div class="mb-8">
            <% duration = calculate_challenge_duration(@challenge) %>
            <p class="text-t66-text-secondary mb-6">
              This is a <strong class="text-[#f0ece6]"><%= duration %>-day challenge</strong>.
              Pick your start date and we'll calculate your end date automatically.
            </p>

            <label class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2">
              When do you want to start?
            </label>
            <input
              type="date"
              value={@join_start_date}
              phx-blur="update_join_date"
              min={Date.to_iso8601(Date.utc_today())}
              class="w-full bg-t66-input border border-[rgba(255,255,255,0.08)] rounded-xl px-4 py-3.5 text-[#f0ece6] focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)] outline-none transition-all"
              style="color-scheme: dark"
            />

            <% end_date = Date.add(Date.from_iso8601!(@join_start_date), duration) %>
            <p class="text-sm text-t66-text-muted mt-3">
              Your challenge will end on:
              <strong class="text-t66-accent">{Calendar.strftime(end_date, "%B %d, %Y")}</strong>
            </p>
          </div>

          <div class="flex gap-3">
            <button
              phx-click="close_join_modal"
              class="flex-1 px-6 py-3.5 bg-[rgba(255,255,255,0.04)] text-t66-text-secondary border border-[rgba(255,255,255,0.06)] rounded-xl font-bold text-[0.8rem] tracking-[1.5px] uppercase hover:border-[rgba(255,255,255,0.12)] hover:text-[#f0ece6] transition-all"
            >
              Cancel
            </button>
            <button
              phx-click={if @challenge.is_template, do: "confirm_start_challenge", else: "confirm_join"}
              class="flex-1 px-6 py-3.5 bg-t66-accent text-white rounded-xl font-bold text-[0.8rem] tracking-[1.5px] uppercase hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)]"
            >
              {if @challenge.is_template, do: "Start Challenge", else: "Join Challenge"}
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <%!-- Report Modal --%>
    <%= if @show_report_modal do %>
      <div class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
        <div class="bg-t66-card border border-[rgba(255,255,255,0.08)] rounded-2xl max-w-md w-full p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-11 h-11 bg-[rgba(239,68,68,0.12)] rounded-xl flex items-center justify-center">
              <.icon name="hero-flag" class="w-5 h-5 text-[#ef4444]" />
            </div>
            <h3 class="font-display text-[1.4rem] tracking-[2px] text-[#f0ece6]">Report Challenge</h3>
          </div>

          <p class="text-sm text-t66-text-muted mb-6">
            Help us keep the community safe. Select a reason for your report.
          </p>

          <form phx-submit="submit_report">
            <div class="mb-4">
              <label class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-3">Reason *</label>
              <div class="space-y-2">
                <%= for reason <- HeadsUp.Reports.Report.reasons() do %>
                  <label class={[
                    "flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-all",
                    if(@report_reason == reason,
                      do: "bg-[rgba(239,68,68,0.12)] ring-2 ring-[rgba(239,68,68,0.3)]",
                      else: "bg-[rgba(255,255,255,0.03)] hover:bg-[rgba(255,255,255,0.06)]"
                    )
                  ]}>
                    <input
                      type="radio"
                      name="report_reason"
                      value={reason}
                      checked={@report_reason == reason}
                      phx-click="update_report_reason"
                      phx-value-report_reason={reason}
                      class="text-[#ef4444] focus:ring-[#ef4444]"
                    />
                    <span class="text-sm font-medium text-t66-text-secondary capitalize">{reason}</span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="mb-6">
              <label for="report_description" class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2">
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
                class="w-full bg-t66-input border border-[rgba(255,255,255,0.08)] rounded-xl px-4 py-3 text-sm text-[#f0ece6] placeholder:text-t66-text-muted focus:border-[rgba(239,68,68,0.4)] focus:ring-[3px] focus:ring-[rgba(239,68,68,0.08)] outline-none transition-all resize-none"
              ><%= @report_description %></textarea>
              <div class="text-xs text-t66-text-muted mt-1 text-right">
                {String.length(@report_description)}/500
              </div>
            </div>

            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="hide_report_modal"
                class="px-5 py-3 bg-[rgba(255,255,255,0.04)] text-t66-text-secondary border border-[rgba(255,255,255,0.06)] rounded-xl text-sm font-bold hover:border-[rgba(255,255,255,0.12)] transition-all"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={@report_reason == ""}
                class="px-5 py-3 bg-[#ef4444] text-white rounded-xl text-sm font-bold hover:bg-[#dc2626] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
              >
                Submit Report
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  defp schedule_label(:daily), do: "Every day"
  defp schedule_label(:twice_week), do: "Twice a week"
  defp schedule_label(:every_other_day), do: "Every other day"
  defp schedule_label(:mon_fri), do: "Mon-Fri"
  defp schedule_label(:custom_weekdays), do: "Custom days"
  defp schedule_label(_), do: "Daily"

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
end
