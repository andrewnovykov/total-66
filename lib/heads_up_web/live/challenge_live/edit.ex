defmodule HeadsUpWeb.ChallengeLive.Edit do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user

    if is_nil(current_user) do
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in")
       |> push_navigate(to: ~p"/users/log_in")}
    else
      challenge = Challenges.get_challenge!(id)

      if challenge.creator_user_id != current_user.id do
        {:ok,
         socket
         |> put_flash(:error, "You can only edit your own challenges")
         |> push_navigate(to: ~p"/challenges/#{id}")}
      else
        changeset = Challenges.change_challenge(challenge)

        socket =
          socket
          |> assign(:challenge, challenge)
          |> assign(:changeset, changeset)
          |> assign(:page_title, "Edit Challenge")

        {:ok, socket}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"challenge" => challenge_params}, socket) do
    changeset =
      socket.assigns.challenge
      |> Challenges.change_challenge(challenge_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"challenge" => challenge_params}, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    case Challenges.update_challenge(challenge, challenge_params, current_user.id) do
      {:ok, updated_challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge updated successfully!")
         |> push_navigate(to: ~p"/challenges/#{updated_challenge.id}")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can only edit your own challenges")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    current_user = socket.assigns.current_user
    challenge = socket.assigns.challenge

    case Challenges.delete_challenge(challenge, current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge deleted successfully!")
         |> push_navigate(to: ~p"/challenges")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can only delete your own challenges")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete challenge")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <.link
        navigate={~p"/challenges/#{@challenge.id}"}
        class="text-blue-600 hover:text-blue-800 mb-4 inline-flex items-center"
      >
        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Challenge
      </.link>

      <h1 class="text-3xl font-bold text-gray-900 mt-4 mb-8">Edit Challenge</h1>

      <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-6">
        <!-- Title -->
        <div>
          <label for="challenge_title" class="block text-sm font-medium text-gray-700 mb-1">
            Title *
          </label>
          <input
            type="text"
            id="challenge_title"
            name="challenge[title]"
            value={@changeset.data.title}
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            required
          />
          <%= if @changeset.errors[:title] do %>
            <p class="text-red-500 text-sm mt-1">{elem(@changeset.errors[:title], 0)}</p>
          <% end %>
        </div>
        
    <!-- Description -->
        <div>
          <label for="challenge_description" class="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            id="challenge_description"
            name="challenge[description]"
            rows="4"
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          ><%= @changeset.data.description || "" %></textarea>
        </div>
        
    <!-- Visibility -->
        <div>
          <label for="challenge_visibility" class="block text-sm font-medium text-gray-700 mb-1">
            Visibility
          </label>
          <select
            id="challenge_visibility"
            name="challenge[visibility]"
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="public" selected={@changeset.data.visibility == :public}>
              Public - Anyone can see and join
            </option>
            <option value="friends" selected={@changeset.data.visibility == :friends}>
              Friends Only - Only friends can see and join
            </option>
            <option value="private" selected={@changeset.data.visibility == :private}>
              Private - Only you can see
            </option>
          </select>
        </div>
        
    <!-- Status -->
        <div>
          <label for="challenge_status" class="block text-sm font-medium text-gray-700 mb-1">
            Status
          </label>
          <select
            id="challenge_status"
            name="challenge[status]"
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="active" selected={@changeset.data.status == :active}>Active</option>
            <option value="paused" selected={@changeset.data.status == :paused}>Paused</option>
            <option value="completed" selected={@changeset.data.status == :completed}>
              Completed
            </option>
            <option value="cancelled" selected={@changeset.data.status == :cancelled}>
              Cancelled
            </option>
          </select>
        </div>
        
    <!-- Date Range -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label for="challenge_start_date" class="block text-sm font-medium text-gray-700 mb-1">
              Start Date
            </label>
            <input
              type="date"
              id="challenge_start_date"
              name="challenge[start_date]"
              value={@changeset.data.start_date && Date.to_iso8601(@changeset.data.start_date)}
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
          <div>
            <label for="challenge_end_date" class="block text-sm font-medium text-gray-700 mb-1">
              End Date
            </label>
            <input
              type="date"
              id="challenge_end_date"
              name="challenge[end_date]"
              value={@changeset.data.end_date && Date.to_iso8601(@changeset.data.end_date)}
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
        </div>
        
    <!-- Submit -->
        <div class="pt-4 flex gap-4">
          <button
            type="submit"
            class="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg"
          >
            Save Changes
          </button>
          <button
            type="button"
            phx-click="delete"
            data-confirm="Are you sure you want to delete this challenge? This cannot be undone."
            class="px-6 py-3 border border-red-300 text-red-600 hover:bg-red-50 rounded-lg font-medium"
          >
            Delete
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
