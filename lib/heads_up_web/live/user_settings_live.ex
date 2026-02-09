defmodule HeadsUpWeb.UserSettingsLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth

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
        <%!-- Panel Header --%>
        <div class="mb-8">
          <h1 class="font-['Bebas_Neue'] text-[clamp(2rem,4vw,2.6rem)] tracking-[3px] text-[#f0ece6] leading-none">
            Settings
          </h1>
          <p class="text-t66-text-muted text-[0.9rem] mt-1.5">
            Manage your account and preferences
          </p>
        </div>

        <%!-- Account Info Row --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 flex items-center gap-4">
            <div class="w-12 h-12 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center flex-shrink-0">
              <.icon name="hero-envelope" class="w-6 h-6 text-t66-accent" />
            </div>
            <div class="min-w-0">
              <p class="text-xs text-t66-text-muted font-medium">Current Email</p>
              <p class="text-sm font-bold text-[#f0ece6] truncate">{@current_email}</p>
            </div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 flex items-center gap-4">
            <div class="w-12 h-12 bg-[rgba(34,197,94,0.12)] rounded-xl flex items-center justify-center flex-shrink-0">
              <.icon name="hero-shield-check" class="w-6 h-6 text-[#22c55e]" />
            </div>
            <div>
              <p class="text-xs text-t66-text-muted font-medium">Account Status</p>
              <p class="text-sm font-bold text-[#22c55e]">Active</p>
            </div>
          </div>
        </div>

        <%!-- Change Email Section --%>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-6 sm:p-8 mb-6">
          <div class="flex items-center gap-4 mb-6">
            <div class="w-11 h-11 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center flex-shrink-0">
              <.icon name="hero-envelope" class="w-5 h-5 text-t66-accent" />
            </div>
            <div>
              <h2 class="font-['Bebas_Neue'] text-[1.3rem] tracking-[2px] text-[#f0ece6]">
                Change Email
              </h2>
              <p class="text-sm text-t66-text-muted">
                Update your email address. A confirmation link will be sent.
              </p>
            </div>
          </div>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="space-y-5"
          >
            <div>
              <label
                for={@email_form[:email].id}
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Email <span class="text-red-400">*</span>
              </label>
              <.input
                field={@email_form[:email]}
                type="email"
                required
                class="w-full !bg-[#0f0f0f] !border !border-white/[0.08] !rounded-xl !px-4 !py-3.5 !text-[#f0ece6] !placeholder-[#5a5754] !text-[0.9rem] !outline-none !transition-all focus:!border-[rgba(255,77,0,0.4)] focus:!shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              />
            </div>

            <div>
              <label
                for="current_password_for_email"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Current Password <span class="text-red-400">*</span>
              </label>
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                value={@email_form_current_password}
                required
                class="w-full !bg-[#0f0f0f] !border !border-white/[0.08] !rounded-xl !px-4 !py-3.5 !text-[#f0ece6] !placeholder-[#5a5754] !text-[0.9rem] !outline-none !transition-all focus:!border-[rgba(255,77,0,0.4)] focus:!shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              />
            </div>

            <div class="pt-2">
              <button
                type="submit"
                phx-disable-with="Changing..."
                class="inline-flex items-center gap-2 bg-t66-accent hover:bg-[#e64400] text-white px-6 py-3 rounded-xl font-bold text-sm transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] hover:-translate-y-0.5"
              >
                <.icon name="hero-envelope" class="w-4 h-4" /> Change Email
              </button>
            </div>
          </.form>
        </div>

        <%!-- Change Password Section --%>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-6 sm:p-8 mb-6">
          <div class="flex items-center gap-4 mb-6">
            <div class="w-11 h-11 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center flex-shrink-0">
              <.icon name="hero-key" class="w-5 h-5 text-t66-accent" />
            </div>
            <div>
              <h2 class="font-['Bebas_Neue'] text-[1.3rem] tracking-[2px] text-[#f0ece6]">
                Change Password
              </h2>
              <p class="text-sm text-t66-text-muted">
                Update your password to keep your account secure.
              </p>
            </div>
          </div>

          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-5"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />

            <div>
              <label
                for={@password_form[:password].id}
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                New Password <span class="text-red-400">*</span>
              </label>
              <.input
                field={@password_form[:password]}
                type="password"
                required
                class="w-full !bg-[#0f0f0f] !border !border-white/[0.08] !rounded-xl !px-4 !py-3.5 !text-[#f0ece6] !placeholder-[#5a5754] !text-[0.9rem] !outline-none !transition-all focus:!border-[rgba(255,77,0,0.4)] focus:!shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              />
            </div>

            <div>
              <label
                for={@password_form[:password_confirmation].id}
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Confirm New Password
              </label>
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                class="w-full !bg-[#0f0f0f] !border !border-white/[0.08] !rounded-xl !px-4 !py-3.5 !text-[#f0ece6] !placeholder-[#5a5754] !text-[0.9rem] !outline-none !transition-all focus:!border-[rgba(255,77,0,0.4)] focus:!shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              />
            </div>

            <div>
              <label
                for="current_password_for_password"
                class="block text-[0.68rem] uppercase tracking-[2px] text-t66-text-muted font-bold mb-2"
              >
                Current Password <span class="text-red-400">*</span>
              </label>
              <.input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                id="current_password_for_password"
                value={@current_password}
                required
                class="w-full !bg-[#0f0f0f] !border !border-white/[0.08] !rounded-xl !px-4 !py-3.5 !text-[#f0ece6] !placeholder-[#5a5754] !text-[0.9rem] !outline-none !transition-all focus:!border-[rgba(255,77,0,0.4)] focus:!shadow-[0_0_0_3px_rgba(255,77,0,0.08)]"
              />
            </div>

            <div class="pt-2">
              <button
                type="submit"
                phx-disable-with="Changing..."
                class="inline-flex items-center gap-2 bg-t66-accent hover:bg-[#e64400] text-white px-6 py-3 rounded-xl font-bold text-sm transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] hover:-translate-y-0.5"
              >
                <.icon name="hero-key" class="w-4 h-4" /> Change Password
              </button>
            </div>
          </.form>
        </div>

        <%!-- Security Tips --%>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-6 sm:p-8">
          <h3 class="font-['Bebas_Neue'] text-[1.3rem] tracking-[2px] text-[#f0ece6] mb-5">
            Security Tips
          </h3>
          <div class="space-y-3">
            <div class="flex items-start gap-3.5 p-4 bg-[#0a0a0a] border border-white/[0.06] rounded-xl">
              <div class="w-9 h-9 bg-[rgba(255,198,66,0.12)] rounded-lg flex items-center justify-center flex-shrink-0">
                <.icon name="hero-lock-closed" class="w-4.5 h-4.5 text-[#ffc642]" />
              </div>
              <div>
                <p class="font-bold text-[#f0ece6] text-sm">Strong Password</p>
                <p class="text-t66-text-muted text-sm mt-0.5">
                  Use at least 12 characters with letters, numbers, and symbols.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3.5 p-4 bg-[#0a0a0a] border border-white/[0.06] rounded-xl">
              <div class="w-9 h-9 bg-[rgba(59,130,246,0.12)] rounded-lg flex items-center justify-center flex-shrink-0">
                <.icon name="hero-finger-print" class="w-4.5 h-4.5 text-[#3b82f6]" />
              </div>
              <div>
                <p class="font-bold text-[#f0ece6] text-sm">Unique Password</p>
                <p class="text-t66-text-muted text-sm mt-0.5">
                  Don't reuse passwords from other services.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3.5 p-4 bg-[#0a0a0a] border border-white/[0.06] rounded-xl">
              <div class="w-9 h-9 bg-[rgba(255,77,0,0.15)] rounded-lg flex items-center justify-center flex-shrink-0">
                <.icon name="hero-arrow-path" class="w-4.5 h-4.5 text-t66-accent" />
              </div>
              <div>
                <p class="font-bold text-[#f0ece6] text-sm">Regular Updates</p>
                <p class="text-t66-text-muted text-sm mt-0.5">
                  Change your password periodically for better security.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Auth.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Auth.change_user_email(user)
    password_changeset = Auth.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Auth.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Auth.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Auth.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Auth.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Auth.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Auth.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
