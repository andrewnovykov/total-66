defmodule HeadsUpWeb.UserResetPasswordLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth

  def render(assigns) do
    errors =
      if assigns.form.source != %{} and assigns.form.errors != [],
        do:
          Enum.map(assigns.form.errors, fn {_field, err} ->
            HeadsUpWeb.CoreComponents.translate_error(err)
          end),
        else: []

    assigns = assign(assigns, :global_errors, errors)

    ~H"""
    <div class="max-w-lg mx-auto py-8">
      <%!-- Hero Banner --%>
      <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 mb-8 relative overflow-hidden text-center text-white soft-shadow">
        <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
          <.icon name="hero-key" class="w-48 h-48" />
        </div>
        <div class="relative z-10">
          <div class="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
            <.icon name="hero-shield-check-solid" class="w-9 h-9 text-white" />
          </div>
          <h1 class="text-3xl sm:text-4xl font-extrabold mb-2 leading-tight">Reset Password</h1>
          <p class="text-blue-100 text-lg">Choose a new password for your account</p>
        </div>
      </div>

      <%!-- Reset Card --%>
      <div class="bg-white rounded-[40px] soft-shadow p-8 sm:p-10">
        <%!-- Global Error --%>
        <div
          :if={@global_errors != []}
          class="mb-6 flex items-center gap-3 bg-red-50 border border-red-200 rounded-2xl px-5 py-4"
        >
          <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-500 flex-shrink-0" />
          <p class="text-sm font-medium text-red-700">
            Oops, something went wrong! Please check the errors below.
          </p>
        </div>

        <.form for={@form} id="reset_password_form" phx-submit="reset_password" phx-change="validate">
          <%!-- New Password Input --%>
          <.reset_field
            field={@form[:password]}
            type="password"
            label="New password"
            placeholder="At least 12 characters"
            icon="hero-lock-closed"
          />

          <%!-- Confirm Password Input --%>
          <.reset_field
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            placeholder="Re-enter your password"
            icon="hero-lock-closed"
          />

          <%!-- Submit Button --%>
          <button
            type="submit"
            phx-disable-with="Resetting..."
            class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold py-4 rounded-2xl text-base hover:scale-[1.02] active:scale-[0.98] transition-transform shadow-lg shadow-blue-500/20 mt-3"
          >
            Reset Password
          </button>
        </.form>

        <%!-- Divider --%>
        <div class="flex items-center gap-4 my-8">
          <div class="flex-1 h-px bg-slate-200"></div>
          <span class="text-sm font-medium text-slate-400">or</span>
          <div class="flex-1 h-px bg-slate-200"></div>
        </div>

        <%!-- Navigation Links --%>
        <p class="text-center text-slate-600 text-base">
          <.link
            href={~p"/users/register"}
            class="font-bold text-blue-600 hover:text-blue-700 transition-colors"
          >
            Register
          </.link>
          <span class="mx-2 text-slate-300">|</span>
          <.link
            href={~p"/users/log_in"}
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

  defp reset_field(assigns) do
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

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Auth.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Auth.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Auth.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Auth.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
