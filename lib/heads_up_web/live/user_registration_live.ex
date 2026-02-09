defmodule HeadsUpWeb.UserRegistrationLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth
  alias HeadsUp.Users

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto py-8">
      <%!-- Hero Banner --%>
      <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 mb-8 relative overflow-hidden text-center text-white soft-shadow">
        <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
          <.icon name="hero-rocket-launch" class="w-48 h-48" />
        </div>
        <div class="relative z-10">
          <div class="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
            <.icon name="hero-user-plus-solid" class="w-9 h-9 text-white" />
          </div>
          <h1 class="text-3xl sm:text-4xl font-extrabold mb-2 leading-tight">Join HeadsUp</h1>
          <p class="text-blue-100 text-lg">Start your journey to achieving more</p>
        </div>
      </div>

      <%!-- Registration Card --%>
      <div class="bg-white rounded-[40px] soft-shadow p-8 sm:p-10">
        <%!-- Global Error --%>
        <div
          :if={@check_errors}
          class="mb-6 flex items-center gap-3 bg-red-50 border border-red-200 rounded-2xl px-5 py-4"
        >
          <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-500 flex-shrink-0" />
          <p class="text-sm font-medium text-red-700">
            Oops, something went wrong! Please check the errors below.
          </p>
        </div>

        <.form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
        >
          <%!-- Username Input --%>
          <.reg_field
            field={@form[:user_name]}
            type="text"
            label="Username"
            placeholder="cooluser42"
            icon="hero-at-symbol"
          />

          <%!-- Full Name Input --%>
          <.reg_field
            field={@form[:name]}
            type="text"
            label="Full Name"
            placeholder="Jane Doe"
            icon="hero-user"
          />

          <%!-- Email Input --%>
          <.reg_field
            field={@form[:email]}
            type="email"
            label="Email"
            placeholder="you@example.com"
            icon="hero-envelope"
          />

          <%!-- Password Input --%>
          <.reg_field
            field={@form[:password]}
            type="password"
            label="Password"
            placeholder="At least 8 characters"
            icon="hero-lock-closed"
          />

          <%!-- Role Select --%>
          <div class="mb-5">
            <label for={@form[:role].id} class="block text-sm font-bold text-slate-700 mb-2">
              I am registering as
            </label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <.icon name="hero-briefcase" class="w-5 h-5 text-slate-400" />
              </div>
              <select
                name={@form[:role].name}
                id={@form[:role].id}
                class="w-full bg-slate-50 border border-slate-200 rounded-2xl h-14 pl-12 pr-5 text-base text-slate-900 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-colors appearance-none"
              >
                <option value="user" selected={@form[:role].value in [nil, "user", :user]}>
                  Regular User
                </option>
                <%!-- <option value="coach" selected={@form[:role].value == "coach"}>Coach</option> --%>
              </select>
              <div class="absolute inset-y-0 right-0 pr-4 flex items-center pointer-events-none">
                <.icon name="hero-chevron-down" class="w-5 h-5 text-slate-400" />
              </div>
            </div>
          </div>

          <%!-- Submit Button --%>
          <button
            type="submit"
            phx-disable-with="Creating account..."
            class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold py-4 rounded-2xl text-base hover:scale-[1.02] active:scale-[0.98] transition-transform shadow-lg shadow-blue-500/20 mt-3"
          >
            Create an account
          </button>
        </.form>

        <%!-- Divider --%>
        <div class="flex items-center gap-4 my-8">
          <div class="flex-1 h-px bg-slate-200"></div>
          <span class="text-sm font-medium text-slate-400">or</span>
          <div class="flex-1 h-px bg-slate-200"></div>
        </div>

        <%!-- Login CTA --%>
        <p class="text-center text-slate-600 text-base">
          Already have an account?
          <.link
            navigate={~p"/users/log_in"}
            class="font-bold text-blue-600 hover:text-blue-700 transition-colors"
          >
            Log in
          </.link>
        </p>
      </div>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: ""
  attr :icon, :string, required: true

  defp reg_field(assigns) do
    errors =
      if Phoenix.Component.used_input?(assigns.field),
        do: Enum.map(assigns.field.errors, &HeadsUpWeb.CoreComponents.translate_error/1),
        else: []

    assigns = assign(assigns, :errors, errors)

    ~H"""
    <div class="mb-5">
      <label for={@field.id} class="block text-sm font-bold text-slate-700 mb-2">{@label}</label>
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
          <.icon name={@icon} class="w-5 h-5 text-slate-400" />
        </div>
        <input
          type={@type}
          name={@field.name}
          id={@field.id}
          value={@field.value}
          required
          class={[
            "w-full bg-slate-50 border rounded-2xl h-14 pl-12 pr-5 text-base text-slate-900 placeholder-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-colors",
            if(@errors == [], do: "border-slate-200", else: "border-red-400")
          ]}
          placeholder={@placeholder}
        />
      </div>
      <p :for={error <- @errors} class="mt-1.5 flex items-center gap-1.5 text-sm text-red-600">
        <.icon name="hero-exclamation-circle-mini" class="w-4 h-4 flex-shrink-0" />
        {error}
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Auth.change_user_registration(%Users{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Auth.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Auth.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Auth.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Auth.change_user_registration(%Users{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
