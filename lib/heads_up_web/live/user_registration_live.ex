defmodule HeadsUpWeb.UserRegistrationLive do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Auth
  alias HeadsUp.Users

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
          <.link navigate={~p"/users/log_in"} class="flex-1 py-3.5 text-center text-[0.8rem] font-bold tracking-[1.5px] uppercase text-t66-text-muted border-b-2 border-transparent hover:text-t66-text-secondary transition-all no-underline">
            Login
          </.link>
          <div class="flex-1 py-3.5 text-center text-[0.8rem] font-bold tracking-[1.5px] uppercase text-t66-accent border-b-2 border-t66-accent cursor-default">
            Register
          </div>
        </div>

        <%!-- Form Body --%>
        <div class="p-9 pt-8">
          <%!-- Global Error --%>
          <div
            :if={@check_errors}
            class="mb-6 flex items-center gap-3 bg-red-500/10 border border-red-500/30 rounded-xl px-5 py-4"
          >
            <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-400 flex-shrink-0" />
            <p class="text-sm font-medium text-red-400">
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
            <%!-- Username --%>
            <.dark_field
              field={@form[:user_name]}
              type="text"
              label="Username"
              placeholder="cooluser42"
              icon="hero-at-symbol"
            />

            <%!-- Full Name --%>
            <.dark_field
              field={@form[:name]}
              type="text"
              label="Full Name"
              placeholder="Jane Doe"
              icon="hero-user"
            />

            <%!-- Email --%>
            <.dark_field
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              icon="hero-envelope"
            />

            <%!-- Password with strength indicator --%>
            <div class="mb-5" x-data={pw_strength_data()}>
              <label for={@form[:password].id} class="block text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted mb-2 font-bold">
                Password
              </label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none opacity-50">
                  <.icon name="hero-lock-closed" class="w-5 h-5 text-t66-text-secondary" />
                </span>
                <input
                  x-bind:type="show ? 'text' : 'password'"
                  x-on:input="checkStrength($event.target.value)"
                  name={@form[:password].name}
                  id={@form[:password].id}
                  value={@form[:password].value}
                  required
                  class={[
                    "w-full py-3.5 pl-[46px] pr-12 bg-t66-input border rounded-xl text-[#f0ece6] text-[0.9rem] outline-none transition-all placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)]",
                    if(has_errors?(@form[:password]), do: "border-red-500/50", else: "border-white/[0.08]")
                  ]}
                  placeholder="Min. 12 characters"
                />
                <button type="button" x-on:click="show = !show" class="absolute right-3.5 top-1/2 -translate-y-1/2 bg-transparent border-none text-t66-text-muted cursor-pointer text-base p-1 hover:text-t66-text-secondary transition-colors">
                  <span x-show="!show"><.icon name="hero-eye" class="w-5 h-5" /></span>
                  <span x-show="show" style="display:none;"><.icon name="hero-eye-slash" class="w-5 h-5" /></span>
                </button>
              </div>
              <%!-- Strength bar --%>
              <div x-show="strength !== ''" class="mt-2" x-cloak>
                <div class="h-[3px] rounded-full bg-white/5 overflow-hidden mb-1">
                  <div
                    class="h-full rounded-full transition-all duration-400"
                    x-bind:class="{
                      'w-1/4 bg-red-500': strength === 'weak',
                      'w-1/2 bg-amber-500': strength === 'fair',
                      'w-3/4 bg-t66-cyan': strength === 'good',
                      'w-full bg-green-500': strength === 'strong'
                    }"
                  ></div>
                </div>
                <div
                  class="text-[0.65rem] tracking-[1px] uppercase"
                  x-bind:class="{
                    'text-red-500': strength === 'weak',
                    'text-amber-500': strength === 'fair',
                    'text-t66-cyan': strength === 'good',
                    'text-green-500': strength === 'strong'
                  }"
                  x-text="strength"
                ></div>
              </div>
              <%!-- Server-side errors --%>
              <.field_errors field={@form[:password]} />
            </div>

            <%!-- Role (hidden, always user) --%>
            <input type="hidden" name={@form[:role].name} value="user" />

            <%!-- I am registering as (visible but locked) --%>
            <div class="mb-5">
              <label class="block text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted mb-2 font-bold">
                I am registering as
              </label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none opacity-50">
                  <.icon name="hero-briefcase" class="w-5 h-5 text-t66-text-secondary" />
                </span>
                <select
                  disabled
                  class="w-full py-3.5 pl-[46px] pr-4 bg-t66-input border border-white/[0.08] rounded-xl text-[#f0ece6] text-[0.9rem] outline-none appearance-none opacity-60 cursor-not-allowed"
                >
                  <option value="user" selected>Regular User</option>
                </select>
                <span class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none opacity-50">
                  <.icon name="hero-chevron-down" class="w-5 h-5 text-t66-text-secondary" />
                </span>
              </div>
            </div>

            <%!-- Submit --%>
            <button
              type="submit"
              phx-disable-with="Creating account..."
              class="w-full py-4 bg-t66-accent text-white border-none rounded-xl font-bold text-[0.85rem] tracking-[2px] uppercase cursor-pointer transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] active:translate-y-0 mt-1"
            >
              Create Account
            </button>
          </.form>
        </div>

        <%!-- Footer --%>
        <div class="text-center px-9 pb-8 text-[0.8rem] text-t66-text-muted">
          Already have an account?
          <.link navigate={~p"/users/log_in"} class="text-t66-accent no-underline font-bold hover:underline">Sign in</.link>
        </div>
      </div>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: ""
  attr :icon, :string, required: true

  defp dark_field(assigns) do
    assigns = assign(assigns, :has_errors, has_errors?(assigns.field))

    ~H"""
    <div class="mb-5">
      <label for={@field.id} class="block text-[0.7rem] uppercase tracking-[2px] text-t66-text-muted mb-2 font-bold">
        {@label}
      </label>
      <div class="relative">
        <span class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none opacity-50">
          <.icon name={@icon} class="w-5 h-5 text-t66-text-secondary" />
        </span>
        <input
          type={@type}
          name={@field.name}
          id={@field.id}
          value={@field.value}
          required
          class={[
            "w-full py-3.5 pl-[46px] pr-4 bg-t66-input border rounded-xl text-[#f0ece6] text-[0.9rem] outline-none transition-all placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)]",
            if(@has_errors, do: "border-red-500/50", else: "border-white/[0.08]")
          ]}
          placeholder={@placeholder}
        />
      </div>
      <.field_errors field={@field} />
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true

  defp field_errors(assigns) do
    errors =
      if Phoenix.Component.used_input?(assigns.field),
        do: Enum.map(assigns.field.errors, &HeadsUpWeb.CoreComponents.translate_error/1),
        else: []

    assigns = assign(assigns, :errors, errors)

    ~H"""
    <p :for={error <- @errors} class="mt-1.5 flex items-center gap-1.5 text-sm text-red-400">
      <.icon name="hero-exclamation-circle-mini" class="w-4 h-4 flex-shrink-0" />
      {error}
    </p>
    """
  end

  defp has_errors?(field) do
    Phoenix.Component.used_input?(field) and field.errors != []
  end

  defp pw_strength_data do
    """
    {
      show: false,
      strength: '',
      checkStrength(pw) {
        if (!pw || pw.length === 0) { this.strength = ''; return; }
        let score = 0;
        if (pw.length >= 8) score++;
        if (pw.length >= 12) score++;
        if (/[A-Z]/.test(pw) && /[a-z]/.test(pw)) score++;
        if (/\\d/.test(pw)) score++;
        if (/[^A-Za-z0-9]/.test(pw)) score++;
        if (score <= 1) this.strength = 'weak';
        else if (score === 2) this.strength = 'fair';
        else if (score === 3) this.strength = 'good';
        else this.strength = 'strong';
      }
    }
    """
  end

  def mount(_params, _session, socket) do
    changeset = Auth.change_user_registration(%Users{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil], layout: false}
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
