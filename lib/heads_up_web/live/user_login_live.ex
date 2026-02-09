defmodule HeadsUpWeb.UserLoginLive do
  use HeadsUpWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto py-8">
      <%!-- Hero Banner --%>
      <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 mb-8 relative overflow-hidden text-center text-white soft-shadow">
        <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
          <.icon name="hero-check-badge" class="w-48 h-48" />
        </div>
        <div class="relative z-10">
          <div class="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
            <.icon name="hero-check-badge-solid" class="w-9 h-9 text-white" />
          </div>
          <h1 class="text-3xl sm:text-4xl font-extrabold mb-2 leading-tight">Welcome Back</h1>
          <p class="text-blue-100 text-lg">Log in to continue your journey</p>
        </div>
      </div>

      <%!-- Login Card --%>
      <div class="bg-white rounded-[40px] soft-shadow p-8 sm:p-10">
        <form action={~p"/users/log_in"} method="post" id="login_form" phx-update="ignore">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <%!-- Email Input --%>
          <div class="mb-5">
            <label for="user_email" class="block text-sm font-bold text-slate-700 mb-2">Email</label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <.icon name="hero-envelope" class="w-5 h-5 text-slate-400" />
              </div>
              <input
                type="email"
                name="user[email]"
                id="user_email"
                value={@form[:email].value}
                required
                class="w-full bg-slate-50 border border-slate-200 rounded-2xl h-14 pl-12 pr-5 text-base text-slate-900 placeholder-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-colors"
                placeholder="you@example.com"
              />
            </div>
          </div>

          <%!-- Password Input --%>
          <div class="mb-5">
            <label for="user_password" class="block text-sm font-bold text-slate-700 mb-2">
              Password
            </label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <.icon name="hero-lock-closed" class="w-5 h-5 text-slate-400" />
              </div>
              <input
                type="password"
                name="user[password]"
                id="user_password"
                required
                class="w-full bg-slate-50 border border-slate-200 rounded-2xl h-14 pl-12 pr-5 text-base text-slate-900 placeholder-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-colors"
                placeholder="Enter your password"
              />
            </div>
          </div>

          <%!-- Remember Me + Forgot Password --%>
          <div class="flex items-center justify-between mb-8">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                name="user[remember_me]"
                id="user_remember_me"
                value="true"
                class="w-5 h-5 rounded-lg border-slate-300 text-blue-600 focus:ring-blue-500/20"
              />
              <span class="text-sm font-medium text-slate-600">Keep me logged in</span>
            </label>
            <.link
              href={~p"/users/reset_password"}
              class="text-sm font-bold text-blue-600 hover:text-blue-700 transition-colors"
            >
              Forgot password?
            </.link>
          </div>

          <%!-- Submit Button --%>
          <button
            type="submit"
            phx-disable-with="Logging in..."
            class="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold py-4 rounded-2xl text-base hover:scale-[1.02] active:scale-[0.98] transition-transform shadow-lg shadow-blue-500/20"
          >
            Log in
          </button>
        </form>

        <%!-- Divider --%>
        <div class="flex items-center gap-4 my-8">
          <div class="flex-1 h-px bg-slate-200"></div>
          <span class="text-sm font-medium text-slate-400">or</span>
          <div class="flex-1 h-px bg-slate-200"></div>
        </div>

        <%!-- Register CTA --%>
        <p class="text-center text-slate-600 text-base">
          Don't have an account?
          <.link
            navigate={~p"/users/register"}
            class="font-bold text-blue-600 hover:text-blue-700 transition-colors"
          >
            Sign up
          </.link>
        </p>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
