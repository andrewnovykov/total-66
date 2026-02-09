defmodule HeadsUpWeb.UserSettingsLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth

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
              Account
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Settings
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Manage your account email address and password settings.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-cog-6-tooth" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Email Section --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="mb-8">
          <div class="flex items-center gap-4 mb-6">
            <div class="w-12 h-12 bg-blue-50 rounded-2xl flex items-center justify-center">
              <.icon name="hero-envelope" class="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h2 class="text-xl font-extrabold text-slate-900">Change Email</h2>
              <p class="text-sm text-slate-400">
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
              <label for={@email_form[:email].id} class="block text-sm font-bold text-slate-700 mb-2">
                Email <span class="text-red-400">*</span>
              </label>
              <.input
                field={@email_form[:email]}
                type="email"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label
                for="current_password_for_email"
                class="block text-sm font-bold text-slate-700 mb-2"
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
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div class="pt-2">
              <button
                type="submit"
                phx-disable-with="Changing..."
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-envelope" class="w-4 h-4" /> Change Email
              </button>
            </div>
          </.form>
        </HeadsUpWeb.Components.UI.Card.card>

        <%!-- Password Section --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg}>
          <div class="flex items-center gap-4 mb-6">
            <div class="w-12 h-12 bg-indigo-50 rounded-2xl flex items-center justify-center">
              <.icon name="hero-key" class="w-6 h-6 text-indigo-600" />
            </div>
            <div>
              <h2 class="text-xl font-extrabold text-slate-900">Change Password</h2>
              <p class="text-sm text-slate-400">Update your password to keep your account secure.</p>
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
                class="block text-sm font-bold text-slate-700 mb-2"
              >
                New Password <span class="text-red-400">*</span>
              </label>
              <.input
                field={@password_form[:password]}
                type="password"
                required
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label
                for={@password_form[:password_confirmation].id}
                class="block text-sm font-bold text-slate-700 mb-2"
              >
                Confirm New Password
              </label>
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div>
              <label
                for="current_password_for_password"
                class="block text-sm font-bold text-slate-700 mb-2"
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
                class="w-full !bg-slate-50 !border-0 !rounded-2xl !px-5 !py-4 !text-slate-900 !placeholder-slate-400 focus:!ring-2 focus:!ring-blue-500 focus:!bg-white !transition-colors"
              />
            </div>

            <div class="pt-2">
              <button
                type="submit"
                phx-disable-with="Changing..."
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-key" class="w-4 h-4" /> Change Password
              </button>
            </div>
          </.form>
        </HeadsUpWeb.Components.UI.Card.card>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Account Info --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Account Info</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-envelope" class="w-7 h-7 text-blue-600" />
              </div>
              <div class="min-w-0">
                <p class="text-xs text-slate-400 font-medium">Current Email</p>
                <p class="text-sm font-extrabold text-slate-900 truncate">{@current_email}</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-shield-check" class="w-7 h-7 text-green-600" />
              </div>
              <div>
                <p class="text-xs text-slate-400 font-medium">Account Status</p>
                <p class="text-sm font-extrabold text-green-600">Active</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Security Tips --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Security Tips</h3>
          <div class="space-y-4">
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-lock-closed" class="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Strong Password</p>
                <p class="text-slate-500 text-sm mt-1">
                  Use at least 12 characters with letters, numbers, and symbols.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-finger-print" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Unique Password</p>
                <p class="text-slate-500 text-sm mt-1">Don't reuse passwords from other services.</p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-arrow-path" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Regular Updates</p>
                <p class="text-slate-500 text-sm mt-1">
                  Change your password periodically for better security.
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
              navigate={~p"/people/#{@current_user.user_name || @current_user.id}"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-user" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Profile</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/my-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Goals</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
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
