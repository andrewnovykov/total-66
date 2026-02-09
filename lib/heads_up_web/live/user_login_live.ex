defmodule HeadsUpWeb.UserLoginLive do
  use HeadsUpWeb, :live_view

  def render(assigns) do
    ~H"""
    <style>
      @keyframes cardIn {
        from { opacity: 0; transform: translateY(30px) scale(0.97); }
        to { opacity: 1; transform: translateY(0) scale(1); }
      }
      @keyframes float1 {
        from { transform: translate(0, 0); }
        to { transform: translate(40px, -30px); }
      }
      @keyframes float2 {
        from { transform: translate(0, 0); }
        to { transform: translate(-30px, 20px); }
      }
    </style>

    <%!-- Shared Nav --%>
    <HeadsUpWeb.Layouts.topnav current_user={nil} />

    <%!-- Auth Page --%>
    <div class="min-h-screen flex items-center justify-center pt-[100px] pb-[60px] px-5 relative bg-[#0a0a0a]">
      <%!-- "66" watermark --%>
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 font-['Bebas_Neue'] text-[clamp(250px,35vw,500px)] text-[rgba(255,77,0,0.025)] pointer-events-none leading-none select-none">66</div>
      <%!-- Glow orbs --%>
      <div class="absolute w-[500px] h-[500px] rounded-full top-[10%] left-[-10%] pointer-events-none" style="background: radial-gradient(circle, rgba(255,77,0,0.06) 0%, transparent 70%); animation: float1 20s ease infinite alternate;"></div>
      <div class="absolute w-[400px] h-[400px] rounded-full bottom-[5%] right-[-5%] pointer-events-none" style="background: radial-gradient(circle, rgba(0,212,170,0.04) 0%, transparent 70%); animation: float2 18s ease infinite alternate;"></div>

      <%!-- Auth Card --%>
      <div class="w-full max-w-[440px] bg-t66-card border border-white/[0.06] rounded-[20px] overflow-hidden relative shadow-[0_24px_80px_rgba(0,0,0,0.5)]" style="animation: cardIn 0.7s cubic-bezier(0.25,0.46,0.45,0.94) both;">
        <%!-- Top gradient bar --%>
        <div class="h-[3px] bg-gradient-to-r from-t66-accent via-t66-accent-secondary to-t66-accent"></div>

        <%!-- Header --%>
        <div class="pt-9 px-9 text-center">
          <div class="font-['Bebas_Neue'] text-[2rem] tracking-[5px] text-[#f0ece6] mb-1.5">
            TOTAL <span class="text-t66-accent">66</span>
          </div>
          <div class="text-t66-text-muted text-[0.85rem] mb-7">
            Join the transformation. 66 days starts now.
          </div>
        </div>

        <%!-- Tabs --%>
        <div class="flex border-b border-white/[0.06] mx-9">
          <div class="flex-1 py-3.5 text-center text-[0.8rem] font-bold tracking-[1.5px] uppercase text-t66-accent border-b-2 border-t66-accent cursor-default">
            Login
          </div>
          <.link navigate={~p"/users/register"} class="flex-1 py-3.5 text-center text-[0.8rem] font-bold tracking-[1.5px] uppercase text-t66-text-muted border-b-2 border-transparent hover:text-t66-text-secondary transition-all no-underline">
            Register
          </.link>
        </div>

        <%!-- Form Body --%>
        <div class="p-9 pt-8">
          <form action={~p"/users/log_in"} method="post" id="login_form" phx-update="ignore">
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

            <%!-- Email --%>
            <div class="mb-5">
              <label for="user_email" class="block text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted mb-2 font-bold">Email</label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 text-base pointer-events-none opacity-50">
                  <.icon name="hero-envelope" class="w-5 h-5 text-t66-text-secondary" />
                </span>
                <input
                  type="email"
                  name="user[email]"
                  id="user_email"
                  value={@form[:email].value}
                  required
                  class="w-full py-3.5 pl-[46px] pr-4 bg-t66-input border border-white/[0.08] rounded-xl text-[#f0ece6] text-[0.9rem] outline-none transition-all placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)]"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            <%!-- Password --%>
            <div class="mb-5" x-data="{ show: false }">
              <label for="user_password" class="block text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted mb-2 font-bold">Password</label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 text-base pointer-events-none opacity-50">
                  <.icon name="hero-lock-closed" class="w-5 h-5 text-t66-text-secondary" />
                </span>
                <input
                  x-bind:type="show ? 'text' : 'password'"
                  name="user[password]"
                  id="user_password"
                  required
                  class="w-full py-3.5 pl-[46px] pr-12 bg-t66-input border border-white/[0.08] rounded-xl text-[#f0ece6] text-[0.9rem] outline-none transition-all placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)]"
                  placeholder="Enter your password"
                />
                <button type="button" x-on:click="show = !show" class="absolute right-3.5 top-1/2 -translate-y-1/2 bg-transparent border-none text-t66-text-muted cursor-pointer text-base p-1 hover:text-t66-text-secondary transition-colors">
                  <span x-show="!show"><.icon name="hero-eye" class="w-5 h-5" /></span>
                  <span x-show="show" style="display:none;"><.icon name="hero-eye-slash" class="w-5 h-5" /></span>
                </button>
              </div>
            </div>

            <%!-- Remember me + Forgot --%>
            <div class="flex items-center justify-between mb-6">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  name="user[remember_me]"
                  id="user_remember_me"
                  value="true"
                  class="w-5 h-5 rounded-md border-white/[0.08] bg-t66-input text-t66-accent focus:ring-t66-accent/20 cursor-pointer"
                />
                <span class="text-[0.8rem] font-medium text-t66-text-secondary">Keep me logged in</span>
              </label>
              <.link
                href={~p"/users/reset_password"}
                class="text-[0.78rem] text-t66-text-muted no-underline hover:text-t66-accent transition-colors"
              >
                Forgot password?
              </.link>
            </div>

            <%!-- Submit --%>
            <button
              type="submit"
              phx-disable-with="Signing in..."
              class="w-full py-4 bg-t66-accent text-white border-none rounded-xl font-bold text-[0.85rem] tracking-[2px] uppercase cursor-pointer transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] active:translate-y-0"
            >
              Sign In
            </button>
          </form>
        </div>

        <%!-- Footer --%>
        <div class="text-center px-9 pb-8 text-[0.8rem] text-t66-text-muted">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="text-t66-accent no-underline font-bold hover:underline">Sign up</.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form], layout: false}
  end
end
