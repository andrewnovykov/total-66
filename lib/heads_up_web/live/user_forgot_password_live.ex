defmodule HeadsUpWeb.UserForgotPasswordLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto py-8">
      <%!-- Hero Banner --%>
      <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 mb-8 relative overflow-hidden text-center text-white soft-shadow">
        <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
          <.icon name="hero-key" class="w-48 h-48" />
        </div>
        <div class="relative z-10">
          <div class="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
            <.icon name="hero-lock-open-solid" class="w-9 h-9 text-white" />
          </div>
          <h1 class="text-3xl sm:text-4xl font-extrabold mb-2 leading-tight">
            Forgot your password?
          </h1>
          <p class="text-blue-100 text-lg">We'll send a password reset link to your inbox</p>
        </div>
      </div>

      <%!-- Reset Card --%>
      <div class="bg-white rounded-[40px] soft-shadow p-8 sm:p-10">
        <.form for={@form} id="reset_password_form" phx-submit="send_email">
          <%!-- Email Input --%>
          <div class="mb-6">
            <label for="user_email" class="block text-sm font-bold text-slate-700 mb-2">
              Email address
            </label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <.icon name="hero-envelope" class="w-5 h-5 text-slate-400" />
              </div>
              <input
                type="email"
                name={@form[:email].name}
                id="user_email"
                required
                class="w-full bg-slate-50 border border-slate-200 rounded-2xl h-14 pl-12 pr-5 text-base text-slate-900 placeholder-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-colors"
                placeholder="you@example.com"
              />
            </div>
          </div>

          <%!-- Submit Button --%>
          <button
            type="submit"
            phx-disable-with="Sending..."
            class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold py-4 rounded-2xl text-base hover:scale-[1.02] active:scale-[0.98] transition-transform shadow-lg shadow-blue-500/20"
          >
            Send password reset instructions
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Auth.get_user_by_email(email) do
      Auth.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
