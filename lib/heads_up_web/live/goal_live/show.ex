defmodule HeadsUpWeb.GoalLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  alias HeadsUp.Reports

  def mount(%{"id" => goal_id}, _session, socket) do
    try do
      {goal_id, _} = Integer.parse(goal_id)
      current_user = socket.assigns[:current_user]
      current_user_id = if current_user, do: current_user.id, else: nil
      goal = Goals.get_goal_with_post_likes!(goal_id, current_user_id)

      # Check if user can access this goal (public goals or user owns the goal)
      can_access = goal.privacy == :public or (current_user && goal.user_id == current_user.id)

      if can_access do
        current_user_id = if current_user, do: current_user.id, else: nil

        # Add social counts - safe handling of associations
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> assign(:current_user_id, current_user_id)
          |> assign(:is_owner, current_user != nil && goal.user_id == current_user.id)
          |> assign(
            :user_liked,
            (current_user_id && Goals.user_liked_goal?(goal_id, current_user_id)) || false
          )
          |> assign(
            :user_subscribed,
            (current_user_id && Goals.user_subscribed_to_goal?(goal_id, current_user_id)) || false
          )
          |> assign(:new_step_title, "")
          |> assign(:editing_step_id, nil)
          |> assign(:editing_step_title, "")
          |> assign(:editing_title, false)
          |> assign(:editing_description, false)
          |> assign(:editing_big_description, false)
          |> assign(:post_content, "")
          |> assign(:post_type, :update)
          |> assign(:post_step_id, nil)
          |> assign(:editing_image, false)
          |> allow_upload(:goal_image,
            accept: ~w(.jpg .jpeg .png),
            max_entries: 1,
            max_file_size: 5_000_000,
            auto_upload: true
          )
          |> assign(:editing_post_id, nil)
          |> assign(:editing_post_content, "")
          |> assign(:show_fail_modal, false)
          |> assign(:failure_reason, "")
          |> assign(:expanded_comments, MapSet.new())
          |> assign(:show_report_modal, false)
          |> assign(:report_target_type, nil)
          |> assign(:report_target_id, nil)
          |> assign(:report_reason, "")
          |> assign(:report_description, "")

        {:ok, socket}
      else
        {:ok,
         socket
         |> put_flash(:error, "Goal not found or you don't have permission to view it.")
         |> push_navigate(to: ~p"/my-goals")}
      end
    rescue
      Ecto.NoResultsError ->
        {:ok,
         socket
         |> put_flash(:error, "Goal not found.")
         |> push_navigate(to: ~p"/my-goals")}
    end
  end

  def handle_event("toggle_like", _params, socket) do
    goal_id = socket.assigns.goal.id
    current_user_id = socket.assigns.current_user_id

    # Prevent users from liking their own goals
    if socket.assigns.is_owner do
      {:noreply, put_flash(socket, :error, "You cannot like your own goal")}
    else
      if socket.assigns.user_liked do
        Goals.unlike_goal(goal_id, current_user_id)

        # Refresh goal data
        goal = Goals.get_goal!(goal_id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> assign(:user_liked, !socket.assigns.user_liked)

        {:noreply, socket}
      else
        case Goals.like_goal(goal_id, current_user_id) do
          {:ok, _} ->
            # Refresh goal data
            goal = Goals.get_goal!(goal_id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket =
              socket
              |> assign(:goal, goal)
              |> assign(:user_liked, !socket.assigns.user_liked)

            {:noreply, socket}

          {:error, :cannot_like_own_goal} ->
            {:noreply, put_flash(socket, :error, "You cannot like your own goal")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to like goal")}
        end
      end
    end
  end

  def handle_event("toggle_subscribe", _params, socket) do
    goal_id = socket.assigns.goal.id
    current_user_id = socket.assigns.current_user_id

    # Prevent users from subscribing to their own goals
    if socket.assigns.is_owner do
      {:noreply, put_flash(socket, :error, "You cannot subscribe to your own goal")}
    else
      if socket.assigns.user_subscribed do
        Goals.unsubscribe_from_goal(goal_id, current_user_id)

        # Refresh goal data
        goal = Goals.get_goal!(goal_id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> assign(:user_subscribed, !socket.assigns.user_subscribed)

        {:noreply, socket}
      else
        case Goals.subscribe_to_goal(goal_id, current_user_id) do
          {:ok, _} ->
            # Refresh goal data
            goal = Goals.get_goal!(goal_id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket =
              socket
              |> assign(:goal, goal)
              |> assign(:user_subscribed, !socket.assigns.user_subscribed)

            {:noreply, socket}

          {:error, :cannot_subscribe_to_own_goal} ->
            {:noreply, put_flash(socket, :error, "You cannot subscribe to your own goal")}

          {:error, :must_be_friends} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "You must be friends with the owner to subscribe to this goal"
             )}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to subscribe to goal")}
        end
      end
    end
  end

  # Goal Step event handlers
  def handle_event("add_step", %{"title" => title}, socket) do
    if String.trim(title) != "" and length(socket.assigns.goal.goal_steps) < 10 do
      order = Goals.get_next_step_order(socket.assigns.goal.id)

      case Goals.create_goal_step_with_ownership(
             %{
               title: String.trim(title),
               goal_id: socket.assigns.goal.id,
               order: order
             },
             socket.assigns.current_user_id
           ) do
        {:ok, _step} ->
          # Refresh goal with updated steps
          goal = Goals.get_goal!(socket.assigns.goal.id)

          # Auto-calculate progress based on steps
          new_progress = calculate_progress_from_steps(goal.goal_steps)

          # Update goal progress
          case Goals.update_goal(goal, %{progress: new_progress}) do
            {:ok, updated_goal} ->
              # Refresh goal with updated progress
              goal = Goals.get_goal!(updated_goal.id)

              like_count =
                if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

              subscriber_count =
                if Ecto.assoc_loaded?(goal.goal_subscriptions),
                  do: length(goal.goal_subscriptions),
                  else: 0

              goal =
                goal
                |> Map.put(:like_count, like_count)
                |> Map.put(:subscriber_count, subscriber_count)

              socket =
                socket
                |> assign(:goal, goal)
                |> assign(:new_step_title, "")

              {:noreply, socket}

            {:error, _changeset} ->
              # Even if progress update fails, show the step
              like_count =
                if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

              subscriber_count =
                if Ecto.assoc_loaded?(goal.goal_subscriptions),
                  do: length(goal.goal_subscriptions),
                  else: 0

              goal =
                goal
                |> Map.put(:like_count, like_count)
                |> Map.put(:subscriber_count, subscriber_count)

              socket =
                socket
                |> assign(:goal, goal)
                |> assign(:new_step_title, "")

              {:noreply, socket}
          end

        {:error, :unauthorized} ->
          {:noreply,
           put_flash(socket, :error, "You are not authorized to add steps to this goal")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to add step")}
      end
    else
      error_msg =
        if length(socket.assigns.goal.goal_steps) >= 10 do
          "Maximum 10 steps allowed"
        else
          "Step title cannot be empty"
        end

      {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  def handle_event("toggle_step", %{"step-id" => step_id}, socket) do
    {step_id, _} = Integer.parse(step_id)
    step = Goals.get_goal_step!(step_id)

    case Goals.toggle_goal_step_completion_with_ownership(step, socket.assigns.current_user_id) do
      {:ok, _step} ->
        # Refresh goal and calculate new progress
        goal = Goals.get_goal!(socket.assigns.goal.id)

        # Auto-calculate progress based on steps
        new_progress = calculate_progress_from_steps(goal.goal_steps)

        # Update goal progress
        case Goals.update_goal(goal, %{progress: new_progress}) do
          {:ok, updated_goal} ->
            # Refresh goal with updated progress
            goal = Goals.get_goal!(updated_goal.id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket = assign(socket, :goal, goal)
            {:noreply, socket}

          {:error, _changeset} ->
            # Even if progress update fails, show the step change
            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket = assign(socket, :goal, goal)
            {:noreply, socket}
        end

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "You are not authorized to modify this goal's steps")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update step")}
    end
  end

  def handle_event("delete_step", %{"step-id" => step_id}, socket) do
    {step_id, _} = Integer.parse(step_id)
    step = Goals.get_goal_step!(step_id)

    case Goals.delete_goal_step_with_ownership(step, socket.assigns.current_user_id) do
      {:ok, _step} ->
        # Refresh goal and calculate new progress
        goal = Goals.get_goal!(socket.assigns.goal.id)

        # Auto-calculate progress based on remaining steps
        new_progress = calculate_progress_from_steps(goal.goal_steps)

        # Update goal progress
        case Goals.update_goal(goal, %{progress: new_progress}) do
          {:ok, updated_goal} ->
            # Refresh goal with updated progress
            goal = Goals.get_goal!(updated_goal.id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket = assign(socket, :goal, goal)
            {:noreply, socket}

          {:error, _changeset} ->
            # Even if progress update fails, show the deleted step
            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket = assign(socket, :goal, goal)
            {:noreply, socket}
        end

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "You are not authorized to delete steps from this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete step")}
    end
  end

  def handle_event("edit_step", %{"step-id" => step_id}, socket) do
    {step_id, _} = Integer.parse(step_id)
    step = Goals.get_goal_step!(step_id)

    socket =
      socket
      |> assign(:editing_step_id, step_id)
      |> assign(:editing_step_title, step.title)

    {:noreply, socket}
  end

  def handle_event("update_step", %{"step-id" => step_id, "title" => title}, socket) do
    if String.trim(title) != "" do
      {step_id, _} = Integer.parse(step_id)
      step = Goals.get_goal_step!(step_id)

      case Goals.update_goal_step_with_ownership(
             step,
             %{title: String.trim(title)},
             socket.assigns.current_user_id
           ) do
        {:ok, _step} ->
          # Refresh goal
          goal = Goals.get_goal!(socket.assigns.goal.id)

          like_count =
            if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

          subscriber_count =
            if Ecto.assoc_loaded?(goal.goal_subscriptions),
              do: length(goal.goal_subscriptions),
              else: 0

          goal =
            goal
            |> Map.put(:like_count, like_count)
            |> Map.put(:subscriber_count, subscriber_count)

          socket =
            socket
            |> assign(:goal, goal)
            |> assign(:editing_step_id, nil)
            |> assign(:editing_step_title, "")

          {:noreply, socket}

        {:error, :unauthorized} ->
          {:noreply,
           put_flash(socket, :error, "You are not authorized to edit steps in this goal")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update step")}
      end
    else
      {:noreply, put_flash(socket, :error, "Step title cannot be empty")}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    socket =
      socket
      |> assign(:editing_step_id, nil)
      |> assign(:editing_step_title, "")

    {:noreply, socket}
  end

  # Goal editing event handlers
  def handle_event("edit_title", _params, socket) do
    socket = assign(socket, :editing_title, true)
    {:noreply, socket}
  end

  def handle_event("cancel_edit_title", _params, socket) do
    socket = assign(socket, :editing_title, false)
    {:noreply, socket}
  end

  def handle_event("update_title", %{"title" => title}, socket) do
    if String.trim(title) != "" do
      case Goals.update_goal_with_ownership(
             socket.assigns.goal,
             %{title: String.trim(title)},
             socket.assigns.current_user_id
           ) do
        {:ok, updated_goal} ->
          # Refresh goal data
          goal = Goals.get_goal!(updated_goal.id)

          like_count =
            if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

          subscriber_count =
            if Ecto.assoc_loaded?(goal.goal_subscriptions),
              do: length(goal.goal_subscriptions),
              else: 0

          goal =
            goal
            |> Map.put(:like_count, like_count)
            |> Map.put(:subscriber_count, subscriber_count)

          socket =
            socket
            |> assign(:goal, goal)
            |> assign(:editing_title, false)
            |> put_flash(:info, "Goal title updated successfully")

          {:noreply, socket}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "You are not authorized to edit this goal")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update title")}
      end
    else
      {:noreply, put_flash(socket, :error, "Title cannot be empty")}
    end
  end

  def handle_event("edit_description", _params, socket) do
    socket = assign(socket, :editing_description, true)
    {:noreply, socket}
  end

  def handle_event("cancel_edit_description", _params, socket) do
    socket = assign(socket, :editing_description, false)
    {:noreply, socket}
  end

  def handle_event("update_description", %{"description" => description}, socket) do
    case Goals.update_goal_with_ownership(
           socket.assigns.goal,
           %{description: String.trim(description)},
           socket.assigns.current_user_id
         ) do
      {:ok, updated_goal} ->
        # Refresh goal data
        goal = Goals.get_goal!(updated_goal.id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> assign(:editing_description, false)
          |> put_flash(:info, "Description updated successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to edit this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update description")}
    end
  end

  def handle_event("edit_big_description", _params, socket) do
    socket = assign(socket, :editing_big_description, true)
    {:noreply, socket}
  end

  def handle_event("cancel_edit_big_description", _params, socket) do
    socket = assign(socket, :editing_big_description, false)
    {:noreply, socket}
  end

  def handle_event("update_big_description", %{"big_description" => big_description}, socket) do
    case Goals.update_goal_with_ownership(
           socket.assigns.goal,
           %{big_description: String.trim(big_description)},
           socket.assigns.current_user_id
         ) do
      {:ok, updated_goal} ->
        # Refresh goal data
        goal = Goals.get_goal!(updated_goal.id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> assign(:editing_big_description, false)
          |> put_flash(:info, "Detailed description updated successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to edit this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update detailed description")}
    end
  end

  # Goal Post event handlers
  def handle_event(
        "create_post",
        %{"content" => content, "post_type" => post_type, "step_id" => step_id},
        socket
      ) do
    if String.trim(content) != "" do
      # Parse step_id (empty string becomes nil)
      step_id =
        case step_id do
          "" -> nil
          id -> String.to_integer(id)
        end

      # Create the post with ownership validation
      case Goals.create_goal_post_with_ownership(
             %{
               content: String.trim(content),
               post_type: String.to_atom(post_type),
               goal_id: socket.assigns.goal.id,
               user_id: socket.assigns.current_user_id,
               step_id: step_id
             },
             socket.assigns.current_user_id
           ) do
        {:ok, _post} ->
          # Refresh goal with updated posts
          goal = Goals.get_goal!(socket.assigns.goal.id)

          like_count =
            if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

          subscriber_count =
            if Ecto.assoc_loaded?(goal.goal_subscriptions),
              do: length(goal.goal_subscriptions),
              else: 0

          goal =
            goal
            |> Map.put(:like_count, like_count)
            |> Map.put(:subscriber_count, subscriber_count)

          socket =
            socket
            |> assign(:goal, goal)
            |> assign(:post_content, "")
            |> assign(:post_type, :update)
            |> assign(:post_step_id, nil)
            |> put_flash(:info, "Post shared successfully!")

          {:noreply, socket}

        {:error, :unauthorized} ->
          {:noreply,
           put_flash(socket, :error, "You are not authorized to create posts in this goal")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to share post")}
      end
    else
      {:noreply, put_flash(socket, :error, "Post content cannot be empty")}
    end
  end

  def handle_event("update_post_content", %{"content" => content}, socket) do
    socket = assign(socket, :post_content, content)
    {:noreply, socket}
  end

  def handle_event("toggle_post_like", %{"post-id" => post_id}, socket) do
    {post_id, _} = Integer.parse(post_id)
    current_user_id = socket.assigns.current_user_id

    if current_user_id do
      # Check if user already liked this post
      if Goals.user_liked_post?(post_id, current_user_id) do
        Goals.unlike_post(post_id, current_user_id)

        # Refresh goal with updated post likes
        goal = Goals.get_goal_with_post_likes!(socket.assigns.goal.id, current_user_id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket = assign(socket, :goal, goal)
        {:noreply, socket}
      else
        case Goals.like_post(post_id, current_user_id) do
          {:ok, _} ->
            # Refresh goal with updated post likes
            goal = Goals.get_goal_with_post_likes!(socket.assigns.goal.id, current_user_id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket = assign(socket, :goal, goal)
            {:noreply, socket}

          {:error, :cannot_like_own_post} ->
            {:noreply, put_flash(socket, :error, "You cannot like your own post")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to like post")}
        end
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to like posts")}
    end
  end

  def handle_event("edit_goal_image", _params, socket) do
    {:noreply, assign(socket, :editing_image, true)}
  end

  def handle_event("cancel_edit_image", _params, socket) do
    socket =
      socket
      |> clear_goal_image_uploads()
      |> assign(:editing_image, false)

    {:noreply, socket}
  end

  def handle_event("validate_goal_image", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :goal_image, ref)}
  end

  def handle_event("save_goal_image", _params, socket) do
    case consume_uploaded_entries(socket, :goal_image, fn %{path: path}, entry ->
           uploads_dir = Path.join(["priv", "static", "uploads"])
           File.mkdir_p!(uploads_dir)

           extension = goal_image_file_extension(path, entry.client_name)

           filename =
             "goal_#{socket.assigns.goal.id}_#{System.unique_integer([:positive])}_#{System.os_time(:second)}#{extension}"

           dest_path = Path.join(uploads_dir, filename)

           case File.rename(path, dest_path) do
             :ok ->
               {:ok, "/uploads/#{filename}"}

             {:error, _} ->
               case File.cp(path, dest_path) do
                 :ok -> {:ok, "/uploads/#{filename}"}
                 {:error, reason} -> {:error, "Failed to save image: #{inspect(reason)}"}
               end
           end
         end) do
      [image_path] when is_binary(image_path) ->
        case Goals.update_goal_with_ownership(
               socket.assigns.goal,
               %{image_path: image_path},
               socket.assigns.current_user_id
             ) do
          {:ok, updated_goal} ->
            goal = refresh_goal(updated_goal.id, socket.assigns.current_user_id)

            {:noreply,
             socket
             |> assign(:goal, goal)
             |> assign(:editing_image, false)
             |> put_flash(:info, "Goal image updated!")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You are not authorized to edit this goal")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update goal image")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Please select an image file")}

      [error] ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("remove_goal_image", _params, socket) do
    case Goals.update_goal_with_ownership(
           socket.assigns.goal,
           %{image_path: nil},
           socket.assigns.current_user_id
         ) do
      {:ok, updated_goal} ->
        goal = refresh_goal(updated_goal.id, socket.assigns.current_user_id)

        {:noreply,
         socket
         |> assign(:goal, goal)
         |> assign(:editing_image, false)
         |> put_flash(:info, "Goal image removed!")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to edit this goal")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove goal image")}
    end
  end

  def handle_event("delete_post", %{"post-id" => post_id}, socket) do
    if socket.assigns.goal.status in [:failed, :deleted] do
      {:noreply,
       put_flash(socket, :error, "Cannot delete posts on a #{socket.assigns.goal.status} goal")}
    else
      {post_id, _} = Integer.parse(post_id)

      # Find the post
      post = Enum.find(socket.assigns.goal.goal_posts, &(&1.id == post_id))

      if post do
        case Goals.delete_goal_post_with_ownership(post, socket.assigns.current_user_id) do
          {:ok, _deleted_post} ->
            # Refresh goal to show updated posts
            current_user_id = socket.assigns.current_user_id
            goal = Goals.get_goal_with_post_likes!(socket.assigns.goal.id, current_user_id)

            like_count =
              if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

            subscriber_count =
              if Ecto.assoc_loaded?(goal.goal_subscriptions),
                do: length(goal.goal_subscriptions),
                else: 0

            goal =
              goal
              |> Map.put(:like_count, like_count)
              |> Map.put(:subscriber_count, subscriber_count)

            socket =
              socket
              |> assign(:goal, goal)
              |> put_flash(:info, "Post deleted successfully")

            {:noreply, socket}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You are not authorized to delete this post")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete post")}
        end
      else
        {:noreply, put_flash(socket, :error, "Post not found")}
      end
    end
  end

  def handle_event("edit_post", %{"post-id" => post_id}, socket) do
    if socket.assigns.goal.status in [:failed, :deleted] do
      {:noreply,
       put_flash(socket, :error, "Cannot edit posts on a #{socket.assigns.goal.status} goal")}
    else
      {post_id, _} = Integer.parse(post_id)

      # Find the post
      post = Enum.find(socket.assigns.goal.goal_posts, &(&1.id == post_id))

      if post && post.user_id == socket.assigns.current_user_id do
        socket =
          socket
          |> assign(:editing_post_id, post_id)
          |> assign(:editing_post_content, post.content)

        {:noreply, socket}
      else
        {:noreply, put_flash(socket, :error, "You are not authorized to edit this post")}
      end
    end
  end

  def handle_event("cancel_edit_post", _params, socket) do
    socket =
      socket
      |> assign(:editing_post_id, nil)
      |> assign(:editing_post_content, "")

    {:noreply, socket}
  end

  def handle_event("update_post", %{"post-id" => post_id, "content" => content}, socket) do
    if socket.assigns.goal.status in [:failed, :deleted] do
      {:noreply,
       put_flash(socket, :error, "Cannot edit posts on a #{socket.assigns.goal.status} goal")}
    else
      {post_id, _} = Integer.parse(post_id)

      if String.trim(content) != "" do
        # Find the post
        post = Enum.find(socket.assigns.goal.goal_posts, &(&1.id == post_id))

        if post do
          case Goals.update_goal_post_with_ownership(
                 post,
                 %{content: String.trim(content)},
                 socket.assigns.current_user_id
               ) do
            {:ok, _updated_post} ->
              # Refresh goal to show updated posts
              current_user_id = socket.assigns.current_user_id
              goal = Goals.get_goal_with_post_likes!(socket.assigns.goal.id, current_user_id)

              like_count =
                if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

              subscriber_count =
                if Ecto.assoc_loaded?(goal.goal_subscriptions),
                  do: length(goal.goal_subscriptions),
                  else: 0

              goal =
                goal
                |> Map.put(:like_count, like_count)
                |> Map.put(:subscriber_count, subscriber_count)

              socket =
                socket
                |> assign(:goal, goal)
                |> assign(:editing_post_id, nil)
                |> assign(:editing_post_content, "")
                |> put_flash(:info, "Post updated successfully")

              {:noreply, socket}

            {:error, :unauthorized} ->
              {:noreply, put_flash(socket, :error, "You are not authorized to edit this post")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to update post")}
          end
        else
          {:noreply, put_flash(socket, :error, "Post not found")}
        end
      else
        {:noreply, put_flash(socket, :error, "Post content cannot be empty")}
      end
    end
  end

  # Comment handlers

  def handle_event("toggle_comments", %{"post-id" => post_id}, socket) do
    case Integer.parse(post_id) do
      {post_id, ""} ->
        expanded = socket.assigns.expanded_comments

        {expanded, goal} =
          if MapSet.member?(expanded, post_id) do
            # Collapse - just remove from set
            {MapSet.delete(expanded, post_id), socket.assigns.goal}
          else
            # Expand - load comments for this post and add to set
            comments = Goals.list_comments(post_id)
            goal = update_post_comments(socket.assigns.goal, post_id, comments)
            {MapSet.put(expanded, post_id), goal}
          end

        {:noreply,
         socket
         |> assign(:expanded_comments, expanded)
         |> assign(:goal, goal)}

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid post")}
    end
  end

  def handle_event("add_comment", %{"post-id" => post_id, "content" => content}, socket) do
    case Integer.parse(post_id) do
      {post_id, ""} ->
        current_user_id = socket.assigns.current_user_id
        goal = socket.assigns.goal

        with true <- post_belongs_to_goal?(goal, post_id),
             true <- can_comment_on_goal?(goal, current_user_id),
             trimmed_content when trimmed_content != "" <- String.trim(content),
             {:ok, comment} <-
               Goals.create_comment(%{
                 goal_post_id: post_id,
                 user_id: current_user_id,
                 content: trimmed_content
               }) do
          # Update in-memory instead of refetching from database
          goal = append_comment_to_post(goal, post_id, comment)
          goal = increment_post_comment_count(goal, post_id)

          {:noreply, assign(socket, :goal, goal)}
        else
          false ->
            {:noreply, put_flash(socket, :error, "You are not allowed to comment on this post")}

          "" ->
            {:noreply, put_flash(socket, :error, "Comment cannot be empty")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to add comment")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid post")}
    end
  end

  def handle_event("delete_comment", %{"comment-id" => comment_id, "post-id" => post_id}, socket) do
    case {Integer.parse(comment_id), Integer.parse(post_id)} do
      {{comment_id, ""}, {post_id, ""}} ->
        comment = Goals.get_comment!(comment_id)

        case Goals.delete_comment(comment, socket.assigns.current_user_id) do
          {:ok, _} ->
            # Update in-memory instead of refetching from database
            goal = remove_comment_from_post(socket.assigns.goal, post_id, comment_id)
            goal = decrement_post_comment_count(goal, post_id)

            {:noreply, assign(socket, :goal, goal)}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You cannot delete this comment")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid comment or post")}
    end
  end

  defp update_post_comments(goal, post_id, comments) do
    posts =
      Enum.map(goal.goal_posts, fn post ->
        if post.id == post_id do
          Map.put(post, :comments, comments)
        else
          post
        end
      end)

    Map.put(goal, :goal_posts, posts)
  end

  # Appends a new comment to the post's comments list (comments are ordered by inserted_at asc)
  defp append_comment_to_post(goal, post_id, comment) do
    posts =
      Enum.map(goal.goal_posts, fn post ->
        if post.id == post_id do
          existing_comments = Map.get(post, :comments, [])
          Map.put(post, :comments, existing_comments ++ [comment])
        else
          post
        end
      end)

    Map.put(goal, :goal_posts, posts)
  end

  # Removes a comment from the post's comments list
  defp remove_comment_from_post(goal, post_id, comment_id) do
    posts =
      Enum.map(goal.goal_posts, fn post ->
        if post.id == post_id do
          filtered_comments = Enum.reject(Map.get(post, :comments, []), &(&1.id == comment_id))
          Map.put(post, :comments, filtered_comments)
        else
          post
        end
      end)

    Map.put(goal, :goal_posts, posts)
  end

  defp increment_post_comment_count(goal, post_id) do
    posts =
      Enum.map(goal.goal_posts, fn post ->
        if post.id == post_id do
          Map.update(post, :comment_count, 1, &((&1 || 0) + 1))
        else
          post
        end
      end)

    Map.put(goal, :goal_posts, posts)
  end

  defp decrement_post_comment_count(goal, post_id) do
    posts =
      Enum.map(goal.goal_posts, fn post ->
        if post.id == post_id do
          Map.update(post, :comment_count, 0, &max((&1 || 0) - 1, 0))
        else
          post
        end
      end)

    Map.put(goal, :goal_posts, posts)
  end

  defp post_belongs_to_goal?(goal, post_id) do
    Enum.any?(goal.goal_posts, &(&1.id == post_id))
  end

  defp can_comment_on_goal?(_goal, nil), do: false
  defp can_comment_on_goal?(%{user_id: owner_id}, owner_id), do: true
  defp can_comment_on_goal?(%{privacy: :public}, _user_id), do: true

  defp can_comment_on_goal?(%{privacy: :friends, user_id: owner_id}, user_id) do
    HeadsUp.Accounts.are_friends?(owner_id, user_id)
  end

  defp can_comment_on_goal?(_goal, _user_id), do: false

  defp refresh_goal(goal_id, current_user_id) do
    goal = Goals.get_goal_with_post_likes!(goal_id, current_user_id)
    like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

    subscriber_count =
      if Ecto.assoc_loaded?(goal.goal_subscriptions), do: length(goal.goal_subscriptions), else: 0

    goal
    |> Map.put(:like_count, like_count)
    |> Map.put(:subscriber_count, subscriber_count)
  end

  defp goal_image_file_extension(temp_path, client_name) do
    client_ext = client_name |> to_string() |> Path.extname() |> String.downcase()

    if client_ext in [".jpg", ".jpeg", ".png"],
      do: client_ext,
      else: temp_path |> Path.extname() |> String.downcase()
  end

  defp clear_goal_image_uploads(socket) do
    entries = socket.assigns.uploads.goal_image.entries

    Enum.reduce(entries, socket, fn entry, acc ->
      cancel_upload(acc, :goal_image, entry.ref)
    end)
  end

  defp upload_error_to_string(:too_large), do: "File is too large. Max size is 5MB."
  defp upload_error_to_string(:not_accepted), do: "Only PNG, JPG, and JPEG files are allowed."
  defp upload_error_to_string(:too_many_files), do: "Please upload only one image."
  defp upload_error_to_string(_), do: "Upload failed. Please try again."

  def handle_event("freeze_goal", _params, socket) do
    case Goals.freeze_goal_with_ownership(socket.assigns.goal, socket.assigns.current_user_id) do
      {:ok, updated_goal} ->
        # Refresh goal with updated status
        current_user_id = socket.assigns.current_user_id
        goal = Goals.get_goal_with_post_likes!(updated_goal.id, current_user_id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> put_flash(:info, "Goal has been frozen. You can unfreeze it anytime.")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to freeze this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to freeze goal")}
    end
  end

  def handle_event("unfreeze_goal", _params, socket) do
    case Goals.unfreeze_goal_with_ownership(socket.assigns.goal, socket.assigns.current_user_id) do
      {:ok, updated_goal} ->
        # Refresh goal with updated status
        current_user_id = socket.assigns.current_user_id
        goal = Goals.get_goal_with_post_likes!(updated_goal.id, current_user_id)
        like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

        subscriber_count =
          if Ecto.assoc_loaded?(goal.goal_subscriptions),
            do: length(goal.goal_subscriptions),
            else: 0

        goal =
          goal
          |> Map.put(:like_count, like_count)
          |> Map.put(:subscriber_count, subscriber_count)

        socket =
          socket
          |> assign(:goal, goal)
          |> put_flash(:info, "Goal has been unfrozen. You can now continue working on it.")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to unfreeze this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unfreeze goal")}
    end
  end

  def handle_event("edit_goal", _params, socket) do
    # Redirect to the goal edit page
    {:noreply, push_navigate(socket, to: ~p"/goals/#{socket.assigns.goal.id}/edit")}
  end

  def handle_event("delete_goal", _params, socket) do
    case Goals.soft_delete_goal_with_ownership(
           socket.assigns.goal,
           socket.assigns.current_user_id
         ) do
      {:ok, _deleted_goal} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Goal has been deleted. You can find it in your deleted goals if you need to restore it."
          )
          |> push_navigate(to: ~p"/my-goals")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to delete this goal")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete goal")}
    end
  end

  def handle_event("show_fail_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_fail_modal, true)
      |> assign(:failure_reason, "")

    {:noreply, socket}
  end

  def handle_event("hide_fail_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_fail_modal, false)
      |> assign(:failure_reason, "")

    {:noreply, socket}
  end

  def handle_event("update_failure_reason", %{"failure_reason" => failure_reason}, socket) do
    socket = assign(socket, :failure_reason, failure_reason)
    {:noreply, socket}
  end

  def handle_event("fail_goal", %{"failure_reason" => failure_reason}, socket) do
    failure_reason = String.trim(failure_reason)

    if failure_reason == "" do
      {:noreply, put_flash(socket, :error, "Please provide a reason for failing this goal")}
    else
      case Goals.fail_goal_with_ownership(
             socket.assigns.goal,
             failure_reason,
             socket.assigns.current_user_id
           ) do
        {:ok, updated_goal} ->
          # Refresh goal with updated status
          current_user_id = socket.assigns.current_user_id
          goal = Goals.get_goal_with_post_likes!(updated_goal.id, current_user_id)

          like_count =
            if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0

          subscriber_count =
            if Ecto.assoc_loaded?(goal.goal_subscriptions),
              do: length(goal.goal_subscriptions),
              else: 0

          goal =
            goal
            |> Map.put(:like_count, like_count)
            |> Map.put(:subscriber_count, subscriber_count)

          socket =
            socket
            |> assign(:goal, goal)
            |> assign(:show_fail_modal, false)
            |> assign(:failure_reason, "")
            |> put_flash(
              :info,
              "Goal has been marked as failed. The failure reason has been recorded."
            )

          {:noreply, socket}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "You are not authorized to fail this goal")}

        {:error, changeset} ->
          error_message =
            case changeset.errors do
              [failure_reason: {msg, _}] -> msg
              _ -> "Failed to mark goal as failed"
            end

          {:noreply, put_flash(socket, :error, error_message)}
      end
    end
  end

  # Helper function to calculate progress based on step completion
  defp calculate_progress_from_steps(steps) when is_list(steps) do
    case length(steps) do
      0 ->
        0

      total_steps ->
        completed_steps = length(Enum.filter(steps, & &1.completed))
        round(completed_steps * 100 / total_steps)
    end
  end

  # ============================================================================
  # Report events
  # ============================================================================

  def handle_event("show_report_modal", %{"type" => type, "id" => id}, socket) do
    if socket.assigns.current_user_id do
      {:noreply,
       socket
       |> assign(:show_report_modal, true)
       |> assign(:report_target_type, type)
       |> assign(:report_target_id, String.to_integer(id))
       |> assign(:report_reason, "")
       |> assign(:report_description, "")}
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to report content")}
    end
  end

  def handle_event("hide_report_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_report_modal, false)
     |> assign(:report_target_type, nil)
     |> assign(:report_target_id, nil)
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
    user_id = socket.assigns.current_user_id
    target_type = socket.assigns.report_target_type
    target_id = socket.assigns.report_target_id

    if reason == "" do
      {:noreply, put_flash(socket, :error, "Please select a reason for your report")}
    else
      attrs = %{reason: reason, description: description}

      result =
        case target_type do
          "goal" -> Reports.report_goal(target_id, user_id, attrs)
          "post" -> Reports.report_post(target_id, user_id, attrs)
          _ -> {:error, :invalid_target}
        end

      case result do
        {:ok, _report} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> assign(:report_target_type, nil)
           |> assign(:report_target_id, nil)
           |> assign(:report_reason, "")
           |> assign(:report_description, "")
           |> put_flash(:info, "Report submitted. Thank you for helping keep the community safe.")}

        {:error, :already_reported} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:info, "You have already reported this content.")}

        {:error, :cannot_report_own} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:error, "You cannot report your own content.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to submit report. Please try again.")}
      end
    end
  end

  defp post_type_badge(:update), do: {"Update", "bg-blue-50 text-blue-600"}
  defp post_type_badge(:milestone), do: {"Milestone", "bg-green-50 text-green-600"}
  defp post_type_badge(:achievement), do: {"Achievement", "bg-amber-50 text-amber-600"}
  defp post_type_badge(:challenge), do: {"Challenge", "bg-red-50 text-red-600"}
  defp post_type_badge(:motivation), do: {"Motivation", "bg-purple-50 text-purple-600"}
  defp post_type_badge(_), do: {"Post", "bg-slate-50 text-slate-600"}

  defp privacy_icon(:public), do: "hero-globe-alt"
  defp privacy_icon(:private), do: "hero-lock-closed"
  defp privacy_icon(:friends), do: "hero-user-group"
  defp privacy_icon(_), do: "hero-globe-alt"

  defp privacy_label(:public), do: "Public"
  defp privacy_label(:private), do: "Private"
  defp privacy_label(:friends), do: "Friends Only"
  defp privacy_label(_), do: "Public"

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <%!-- Back link --%>
            <.link
              navigate={~p"/goals-category/#{@goal.group_id}"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" />
              {if @goal.group, do: @goal.group.name, else: "Goals"}
            </.link>

            <div class="flex flex-col sm:flex-row sm:items-start gap-6">
              <%!-- Goal Image --%>
              <div class="relative w-24 sm:w-28 h-24 sm:h-28 flex-shrink-0">
                <%= if @goal.image_path do %>
                  <img
                    src={@goal.image_path}
                    alt={@goal.title}
                    class="w-full h-full object-cover rounded-2xl border-4 border-white/20"
                  />
                <% else %>
                  <div class="w-full h-full bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center border-4 border-white/10">
                    <.icon name="hero-flag" class="w-10 h-10 text-white/80" />
                  </div>
                <% end %>
                <%= if @is_owner and @goal.status != :frozen do %>
                  <button
                    phx-click="edit_goal_image"
                    class="absolute -bottom-2 -right-2 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-lg text-blue-600 hover:text-blue-800 transition-colors"
                    title="Edit goal image"
                  >
                    <.icon name="hero-camera" class="w-4 h-4" />
                  </button>
                <% end %>
              </div>

              <div class="flex-1 min-w-0">
                <%!-- Title --%>
                <%= if @editing_title do %>
                  <form phx-submit="update_title" class="space-y-3">
                    <input
                      name="title"
                      type="text"
                      value={@goal.title}
                      maxlength="255"
                      class="w-full text-2xl sm:text-3xl font-extrabold bg-white/20 backdrop-blur-sm text-white placeholder-blue-200 border border-white/30 rounded-2xl px-4 py-3 focus:ring-0 focus:bg-white/30"
                    />
                    <div class="flex gap-2">
                      <button
                        type="submit"
                        class="px-4 py-2 bg-white text-blue-600 rounded-xl text-sm font-bold hover:bg-blue-50 transition-colors"
                      >
                        Save
                      </button>
                      <button
                        type="button"
                        phx-click="cancel_edit_title"
                        class="px-4 py-2 bg-white/20 text-white rounded-xl text-sm font-bold hover:bg-white/30 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                <% else %>
                  <div class="flex items-start gap-3">
                    <h1 class="text-2xl sm:text-3xl lg:text-4xl font-extrabold leading-tight flex-1">
                      {@goal.title}
                    </h1>
                    <%= if @is_owner do %>
                      <button
                        phx-click="edit_title"
                        class="text-blue-200 hover:text-white transition-colors mt-1"
                        title="Edit title"
                      >
                        <.icon name="hero-pencil-square" class="w-5 h-5" />
                      </button>
                    <% end %>
                  </div>
                <% end %>

                <%!-- Badges row --%>
                <div class="flex flex-wrap items-center gap-3 mt-4">
                  <HeadsUpWeb.Components.UI.StatusBadge.status_badge status={@goal.status} size={:md} />
                  <span class="inline-flex items-center gap-1.5 bg-white/20 backdrop-blur-sm text-white text-sm font-bold px-4 py-2 rounded-full">
                    <.icon name={privacy_icon(@goal.privacy)} class="w-4 h-4" />
                    {privacy_label(@goal.privacy)}
                  </span>
                  <%= if @goal.group do %>
                    <.link
                      navigate={~p"/goals-category/#{@goal.group_id}"}
                      class="inline-flex items-center gap-1.5 bg-white/20 backdrop-blur-sm text-white text-sm font-bold px-4 py-2 rounded-full hover:bg-white/30 transition-colors"
                    >
                      <.icon name="hero-tag" class="w-4 h-4" />
                      {@goal.group.name}
                    </.link>
                  <% end %>
                </div>

                <%!-- Engagement stats --%>
                <div class="flex items-center gap-6 mt-4 text-blue-100 text-sm font-medium">
                  <span class="flex items-center gap-1.5">
                    <.icon name="hero-heart" class="w-4 h-4" />
                    {@goal.like_count} {if @goal.like_count == 1, do: "like", else: "likes"}
                  </span>
                  <span class="flex items-center gap-1.5">
                    <.icon name="hero-eye" class="w-4 h-4" />
                    {@goal.subscriber_count} {if @goal.subscriber_count == 1,
                      do: "subscriber",
                      else: "subscribers"}
                  </span>
                  <span class="flex items-center gap-1.5">
                    <.icon name="hero-chat-bubble-left" class="w-4 h-4" />
                    {length(@goal.goal_posts)} {if length(@goal.goal_posts) == 1,
                      do: "post",
                      else: "posts"}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-flag" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Image Upload Section --%>
        <%= if @editing_image do %>
          <div class="mb-8">
            <HeadsUpWeb.Components.UI.Card.card>
              <h4 class="text-lg font-extrabold text-slate-900 mb-4">Update Goal Image</h4>
              <form phx-submit="save_goal_image" phx-change="validate_goal_image" class="space-y-4">
                <div class="flex items-center justify-center w-full">
                  <div
                    phx-drop-target={@uploads.goal_image.ref}
                    class="relative flex flex-col items-center justify-center w-full h-36 border-2 border-slate-200 border-dashed rounded-2xl bg-slate-50 hover:bg-slate-100 transition-colors"
                  >
                    <div class="flex flex-col items-center justify-center pt-5 pb-6">
                      <.icon name="hero-cloud-arrow-up" class="w-8 h-8 text-slate-400 mb-3" />
                      <p class="mb-1 text-sm text-slate-600">
                        <span class="font-bold">Click to upload</span> or drag and drop
                      </p>
                      <p class="text-xs text-slate-400">PNG, JPG or JPEG (MAX. 5MB)</p>
                    </div>
                    <.live_file_input
                      upload={@uploads.goal_image}
                      class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    />
                  </div>
                </div>

                <%!-- Upload Progress --%>
                <%= for entry <- @uploads.goal_image.entries do %>
                  <div class="space-y-2">
                    <div class="flex items-center gap-3">
                      <.live_img_preview entry={entry} class="w-16 h-16 rounded-xl object-cover" />
                      <div class="flex-1">
                        <p class="text-sm font-bold text-slate-700 truncate">{entry.client_name}</p>
                        <div class="flex items-center gap-2 mt-1">
                          <div class="flex-1 bg-slate-200 rounded-full h-2">
                            <div
                              class="bg-gradient-to-r from-blue-500 to-indigo-600 h-2 rounded-full transition-all duration-300"
                              style={"width: #{entry.progress}%"}
                            />
                          </div>
                          <span class="text-xs text-slate-500 font-medium">{entry.progress}%</span>
                        </div>
                      </div>
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="w-8 h-8 bg-red-50 rounded-lg flex items-center justify-center text-red-500 hover:bg-red-100 transition-colors"
                      >
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                      </button>
                    </div>

                    <%= for err <- upload_errors(@uploads.goal_image, entry) do %>
                      <p class="text-sm text-red-600 font-medium">{upload_error_to_string(err)}</p>
                    <% end %>
                  </div>
                <% end %>

                <%= for err <- upload_errors(@uploads.goal_image) do %>
                  <p class="text-sm text-red-600 font-medium">{upload_error_to_string(err)}</p>
                <% end %>

                <div class="flex gap-3">
                  <button
                    type="submit"
                    disabled={@uploads.goal_image.entries == []}
                    class="px-5 py-2.5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold rounded-xl shadow-lg shadow-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Save Image
                  </button>
                  <button
                    type="button"
                    phx-click="cancel_edit_image"
                    class="px-5 py-2.5 bg-slate-100 text-slate-600 text-sm font-bold rounded-xl hover:bg-slate-200 transition-colors"
                  >
                    Cancel
                  </button>
                  <%= if @goal.image_path do %>
                    <button
                      type="button"
                      phx-click="remove_goal_image"
                      class="px-5 py-2.5 bg-red-50 text-red-600 text-sm font-bold rounded-xl hover:bg-red-100 transition-colors"
                    >
                      Remove
                    </button>
                  <% end %>
                </div>
              </form>
            </HeadsUpWeb.Components.UI.Card.card>
          </div>
        <% end %>

        <%!-- Progress Section --%>
        <div class="mb-8">
          <HeadsUpWeb.Components.UI.Card.card>
            <HeadsUpWeb.Components.UI.ProgressBar.progress_bar
              value={@goal.progress}
              color={:indigo}
              size={:lg}
              show_label
            />
          </HeadsUpWeb.Components.UI.Card.card>
        </div>

        <%!-- Description Section --%>
        <div class="mb-8">
          <HeadsUpWeb.Components.UI.Card.card>
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-xl font-extrabold text-slate-900">About This Goal</h3>
              <%= if @is_owner and @goal.status != :frozen do %>
                <button
                  phx-click="edit_big_description"
                  class="text-sm text-blue-600 hover:text-blue-800 font-bold transition-colors"
                >
                  {if @goal.big_description && String.trim(@goal.big_description) != "",
                    do: "Edit",
                    else: "Add Description"}
                </button>
              <% end %>
            </div>

            <%!-- Short description --%>
            <%= if @editing_description do %>
              <form phx-submit="update_description" class="space-y-3 mb-4">
                <textarea
                  name="description"
                  rows="2"
                  placeholder="Brief description..."
                  class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 resize-none"
                ><%= @goal.description || "" %></textarea>
                <div class="flex gap-2">
                  <button
                    type="submit"
                    class="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-sm font-bold"
                  >
                    Save
                  </button>
                  <button
                    type="button"
                    phx-click="cancel_edit_description"
                    class="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            <% else %>
              <div class="flex items-start gap-3 mb-4">
                <%= if @goal.description && String.trim(@goal.description) != "" do %>
                  <p class="text-slate-500 text-base leading-relaxed flex-1">{@goal.description}</p>
                <% else %>
                  <p class="text-slate-400 text-base italic flex-1">No short description yet.</p>
                <% end %>
                <%= if @is_owner and @goal.status != :frozen do %>
                  <button
                    phx-click="edit_description"
                    class="text-sm text-blue-600 hover:text-blue-800 font-bold transition-colors"
                    title="Edit description"
                  >
                    {if @goal.description && String.trim(@goal.description) != "",
                      do: "Edit",
                      else: "Add"}
                  </button>
                <% end %>
              </div>
            <% end %>

            <%!-- Big description --%>
            <%= if @editing_big_description do %>
              <form phx-submit="update_big_description" class="space-y-3">
                <textarea
                  name="big_description"
                  rows="6"
                  placeholder="Write a detailed description..."
                  class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 resize-none"
                ><%= @goal.big_description || "" %></textarea>
                <div class="flex gap-2">
                  <button
                    type="submit"
                    class="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-sm font-bold"
                  >
                    Save
                  </button>
                  <button
                    type="button"
                    phx-click="cancel_edit_big_description"
                    class="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            <% else %>
              <%= if @goal.big_description && String.trim(@goal.big_description) != "" do %>
                <div class="prose max-w-none text-slate-600 leading-relaxed whitespace-pre-wrap text-base">
                  {@goal.big_description}
                </div>
              <% else %>
                <p class="text-slate-400 italic text-sm">No detailed description yet.</p>
              <% end %>
            <% end %>
          </HeadsUpWeb.Components.UI.Card.card>
        </div>

        <%!-- Goal Steps Section --%>
        <div class="mb-8">
          <HeadsUpWeb.Components.UI.Card.card>
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-xl font-extrabold text-slate-900">Goal Steps</h3>
              <span class="text-sm text-slate-400 font-medium">
                {length(Enum.filter(@goal.goal_steps, & &1.completed))}/{length(@goal.goal_steps)} completed
              </span>
            </div>

            <%!-- Add New Step Form --%>
            <%= if @is_owner and @goal.status not in [:frozen, :failed, :deleted] do %>
              <form phx-submit="add_step" class="mb-6">
                <div class="flex gap-3">
                  <input
                    name="title"
                    type="text"
                    value={@new_step_title}
                    placeholder="Add a new step..."
                    maxlength="255"
                    disabled={length(@goal.goal_steps) >= 10}
                    class="flex-1 bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                  />
                  <button
                    type="submit"
                    disabled={length(@goal.goal_steps) >= 10}
                    class="px-5 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-sm font-bold shadow-lg shadow-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Add Step
                  </button>
                </div>
                <%= if length(@goal.goal_steps) >= 10 do %>
                  <p class="text-xs text-amber-600 mt-2 font-medium">Maximum 10 steps allowed</p>
                <% end %>
              </form>
            <% end %>

            <%!-- Steps List --%>
            <%= if Enum.empty?(@goal.goal_steps) do %>
              <div class="text-center py-10">
                <div class="w-16 h-16 mx-auto bg-slate-100 rounded-full flex items-center justify-center mb-4">
                  <.icon name="hero-clipboard-document-list" class="w-8 h-8 text-slate-400" />
                </div>
                <p class="text-slate-400 text-sm font-medium">No steps added yet.</p>
              </div>
            <% else %>
              <div class="space-y-3">
                <div
                  :for={step <- @goal.goal_steps}
                  class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
                >
                  <%!-- Checkbox --%>
                  <%= if @is_owner and @goal.status not in [:frozen, :failed, :deleted] do %>
                    <button
                      phx-click="toggle_step"
                      phx-value-step-id={step.id}
                      class={"w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-colors flex-shrink-0 #{if step.completed, do: "bg-green-500 border-green-500", else: "border-slate-300 hover:border-green-400"}"}
                    >
                      <%= if step.completed do %>
                        <.icon name="hero-check" class="w-4 h-4 text-white" />
                      <% end %>
                    </button>
                  <% else %>
                    <div class={"w-6 h-6 rounded-lg border-2 flex items-center justify-center flex-shrink-0 #{if step.completed, do: "bg-green-500 border-green-500", else: "border-slate-300"}"}>
                      <%= if step.completed do %>
                        <.icon name="hero-check" class="w-4 h-4 text-white" />
                      <% end %>
                    </div>
                  <% end %>

                  <%!-- Step Content --%>
                  <div class="flex-1 min-w-0">
                    <%= if @editing_step_id == step.id do %>
                      <form phx-submit="update_step" phx-value-step-id={step.id} class="flex gap-2">
                        <input
                          name="title"
                          type="text"
                          value={@editing_step_title}
                          maxlength="255"
                          class="flex-1 bg-white border-none rounded-xl px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500"
                        />
                        <button
                          type="submit"
                          class="px-3 py-2 bg-green-500 text-white rounded-xl text-xs font-bold"
                        >
                          Save
                        </button>
                        <button
                          type="button"
                          phx-click="cancel_edit"
                          class="px-3 py-2 bg-slate-200 text-slate-600 rounded-xl text-xs font-bold"
                        >
                          Cancel
                        </button>
                      </form>
                    <% else %>
                      <span class={"text-sm font-medium #{if step.completed, do: "line-through text-slate-400", else: "text-slate-900"}"}>
                        {step.title}
                      </span>
                    <% end %>
                  </div>

                  <%!-- Action Buttons --%>
                  <%= if @editing_step_id != step.id && @is_owner and @goal.status not in [:frozen, :failed, :deleted] do %>
                    <div class="flex gap-1 flex-shrink-0">
                      <button
                        phx-click="edit_step"
                        phx-value-step-id={step.id}
                        class="p-2 text-slate-400 hover:text-blue-600 transition-colors rounded-lg hover:bg-blue-50"
                        title="Edit step"
                      >
                        <.icon name="hero-pencil-square" class="w-4 h-4" />
                      </button>
                      <button
                        phx-click="delete_step"
                        phx-value-step-id={step.id}
                        data-confirm="Are you sure you want to delete this step?"
                        class="p-2 text-slate-400 hover:text-red-600 transition-colors rounded-lg hover:bg-red-50"
                        title="Delete step"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </HeadsUpWeb.Components.UI.Card.card>
        </div>

        <%!-- Goal Management Section (owner only) --%>
        <%= if @is_owner do %>
          <div class="mb-8">
            <HeadsUpWeb.Components.UI.Card.card>
              <h3 class="text-xl font-extrabold text-slate-900 mb-6">Goal Management</h3>
              <div class="flex flex-wrap gap-3">
                <%= if @goal.status not in [:failed, :completed, :deleted] do %>
                  <%= if @goal.status == :frozen do %>
                    <button
                      phx-click="unfreeze_goal"
                      data-confirm="Are you sure you want to unfreeze this goal?"
                      class="inline-flex items-center gap-2 px-5 py-3 bg-green-500 text-white rounded-xl text-sm font-bold hover:bg-green-600 transition-colors"
                    >
                      <.icon name="hero-sun" class="w-4 h-4" /> Unfreeze Goal
                    </button>
                  <% else %>
                    <button
                      phx-click="freeze_goal"
                      data-confirm="Are you sure you want to freeze this goal?"
                      class="inline-flex items-center gap-2 px-5 py-3 bg-purple-500 text-white rounded-xl text-sm font-bold hover:bg-purple-600 transition-colors"
                    >
                      <.icon name="hero-lock-closed" class="w-4 h-4" /> Freeze Goal
                    </button>
                  <% end %>

                  <button
                    phx-click="edit_goal"
                    class="inline-flex items-center gap-2 px-5 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-sm font-bold shadow-lg shadow-blue-500/20"
                  >
                    <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit Goal Details
                  </button>
                <% end %>

                <%= if @goal.status not in [:failed, :deleted] do %>
                  <button
                    phx-click="show_fail_modal"
                    class="inline-flex items-center gap-2 px-5 py-3 bg-amber-500 text-white rounded-xl text-sm font-bold hover:bg-amber-600 transition-colors"
                  >
                    <.icon name="hero-exclamation-triangle" class="w-4 h-4" /> Fail Goal
                  </button>
                <% end %>

                <button
                  phx-click="delete_goal"
                  data-confirm="Are you sure you want to delete this goal?"
                  class="inline-flex items-center gap-2 px-5 py-3 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600 transition-colors"
                >
                  <.icon name="hero-trash" class="w-4 h-4" /> Delete Goal
                </button>
              </div>

              <%= if @goal.status == :frozen do %>
                <div class="mt-4 p-4 bg-purple-50 rounded-2xl">
                  <p class="text-sm text-purple-700 font-medium">
                    This goal is frozen. Editing, steps, and posting are disabled until you unfreeze it.
                  </p>
                </div>
              <% end %>

              <%= if @goal.status == :failed do %>
                <div class="mt-4 p-4 bg-amber-50 rounded-2xl">
                  <p class="text-sm text-amber-700 font-medium">
                    This goal has been marked as failed. Editing and posting are disabled.
                  </p>
                </div>
              <% end %>
            </HeadsUpWeb.Components.UI.Card.card>
          </div>
        <% end %>

        <%!-- Create Post Card --%>
        <%= if @is_owner and @goal.status not in [:frozen, :failed, :deleted] do %>
          <div class="mb-8">
            <HeadsUpWeb.Components.UI.Card.card>
              <h3 class="text-xl font-extrabold text-slate-900 mb-6">Share an Update</h3>
              <form phx-submit="create_post" class="space-y-4">
                <textarea
                  name="content"
                  rows="3"
                  placeholder="What's your update? Share your progress..."
                  value={@post_content}
                  maxlength="1000"
                  phx-change="update_post_content"
                  required
                  class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 resize-none"
                ><%= @post_content %></textarea>
                <div class="text-xs text-slate-400 text-right font-medium">
                  {String.length(@post_content)}/1000
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-bold text-slate-700 mb-2">Post Type</label>
                    <select
                      name="post_type"
                      value={@post_type}
                      class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="update">General Update</option>
                      <option value="achievement">Achievement</option>
                      <option value="milestone">Milestone</option>
                      <option value="challenge">Challenge</option>
                      <option value="motivation">Motivation</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-bold text-slate-700 mb-2">Related To</label>
                    <select
                      name="step_id"
                      value={@post_step_id || ""}
                      class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">General Goal Update</option>
                      <%= for step <- @goal.goal_steps do %>
                        <option value={step.id}>{step.title}</option>
                      <% end %>
                    </select>
                  </div>
                </div>
                <div class="flex justify-end">
                  <button
                    type="submit"
                    disabled={String.trim(@post_content) == ""}
                    class="px-6 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-sm font-bold shadow-lg shadow-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Share Update
                  </button>
                </div>
              </form>
            </HeadsUpWeb.Components.UI.Card.card>
          </div>
        <% end %>

        <%!-- Goal Feed --%>
        <div class="mb-8">
          <h2 class="text-2xl font-extrabold text-slate-900 mb-6">Goal Feed</h2>

          <%= if @goal.goal_posts && length(@goal.goal_posts) > 0 do %>
            <div class="space-y-6">
              <div :for={post <- @goal.goal_posts}>
                <HeadsUpWeb.Components.UI.Card.card>
                  <%!-- Post header --%>
                  <div class="flex items-start justify-between mb-4">
                    <div class="flex items-center gap-3">
                      <HeadsUpWeb.Components.UI.Avatar.avatar
                        name={post.user.name || "User"}
                        src={post.user.image_path}
                        size={:lg}
                      />
                      <div>
                        <p class="font-extrabold text-slate-900">{post.user.name}</p>
                        <div class="flex items-center gap-2 mt-0.5">
                          <% {type_label, type_class} = post_type_badge(post.post_type) %>
                          <span class={"inline-flex items-center px-3 py-1 rounded-full text-xs font-bold #{type_class}"}>
                            {type_label}
                          </span>
                          <span class="text-xs text-slate-400">
                            {Calendar.strftime(post.inserted_at, "%b %d at %I:%M %p")}
                          </span>
                        </div>
                      </div>
                    </div>

                    <%!-- Post action buttons (author only, not on failed/deleted goals) --%>
                    <%= if @current_user_id && @current_user_id == post.user_id && @goal.status not in [:failed, :deleted] do %>
                      <div class="flex gap-1">
                        <button
                          phx-click="edit_post"
                          phx-value-post-id={post.id}
                          class="p-2 text-slate-400 hover:text-blue-600 rounded-lg hover:bg-blue-50 transition-colors"
                          title="Edit post"
                        >
                          <.icon name="hero-pencil-square" class="w-4 h-4" />
                        </button>
                        <button
                          phx-click="delete_post"
                          phx-value-post-id={post.id}
                          data-confirm="Are you sure you want to delete this post?"
                          class="p-2 text-slate-400 hover:text-red-600 rounded-lg hover:bg-red-50 transition-colors"
                          title="Delete post"
                        >
                          <.icon name="hero-trash" class="w-4 h-4" />
                        </button>
                      </div>
                    <% end %>
                  </div>

                  <%!-- Step reference --%>
                  <%= if post.step_id do %>
                    <%= if step = Enum.find(@goal.goal_steps, &(&1.id == post.step_id)) do %>
                      <div class="flex items-center gap-1.5 text-xs text-slate-400 font-medium mb-3">
                        <.icon name="hero-clipboard-document-list" class="w-3.5 h-3.5" />
                        Related to step: <span class="font-bold text-slate-500">{step.title}</span>
                      </div>
                    <% end %>
                  <% end %>

                  <%!-- Post content --%>
                  <%= if @editing_post_id == post.id do %>
                    <form phx-submit="update_post" phx-value-post-id={post.id} class="space-y-3">
                      <textarea
                        name="content"
                        rows="3"
                        maxlength="1000"
                        required
                        class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 resize-none"
                      ><%= @editing_post_content %></textarea>
                      <div class="flex justify-end gap-2">
                        <button
                          type="button"
                          phx-click="cancel_edit_post"
                          class="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          class="px-4 py-2 bg-green-500 text-white rounded-xl text-sm font-bold"
                        >
                          Save
                        </button>
                      </div>
                    </form>
                  <% else %>
                    <p class="text-slate-700 text-base leading-relaxed">{post.content}</p>
                  <% end %>

                  <%= if post.image_path do %>
                    <div class="mt-4">
                      <img
                        src={post.image_path}
                        alt="Post image"
                        class="rounded-[32px] max-w-full h-auto"
                      />
                    </div>
                  <% end %>

                  <%!-- Engagement row --%>
                  <div class="flex items-center gap-6 mt-5 pt-5 border-t border-slate-100">
                    <%!-- Like button --%>
                    <%= if @current_user_id && @current_user_id != post.user_id do %>
                      <button
                        phx-click="toggle_post_like"
                        phx-value-post-id={post.id}
                        class={"flex items-center gap-1.5 text-sm font-bold transition-colors #{if Map.get(post, :user_liked, false), do: "text-red-500", else: "text-slate-400 hover:text-red-500"}"}
                      >
                        <%= if Map.get(post, :user_liked, false) do %>
                          <.icon name="hero-heart-solid" class="w-5 h-5" />
                        <% else %>
                          <.icon name="hero-heart" class="w-5 h-5" />
                        <% end %>
                        {Map.get(post, :like_count, 0)}
                      </button>
                    <% else %>
                      <span class="flex items-center gap-1.5 text-sm font-bold text-slate-400">
                        <.icon name="hero-heart" class="w-5 h-5" />
                        {Map.get(post, :like_count, 0)}
                      </span>
                    <% end %>

                    <%!-- Comments toggle --%>
                    <button
                      phx-click="toggle_comments"
                      phx-value-post-id={post.id}
                      class="flex items-center gap-1.5 text-sm font-bold text-slate-400 hover:text-blue-600 transition-colors"
                    >
                      <.icon name="hero-chat-bubble-left" class="w-5 h-5" />
                      {Map.get(post, :comment_count, 0)} comments
                    </button>

                    <%!-- Report flag --%>
                    <%= if @current_user_id && @current_user_id != post.user_id do %>
                      <button
                        phx-click="show_report_modal"
                        phx-value-type="post"
                        phx-value-id={post.id}
                        class="flex items-center gap-1.5 text-sm font-bold text-slate-400 hover:text-red-500 transition-colors ml-auto"
                        title="Report post"
                      >
                        <.icon name="hero-flag" class="w-5 h-5" />
                      </button>
                    <% end %>
                  </div>

                  <%!-- Comments section (collapsible) --%>
                  <%= if MapSet.member?(@expanded_comments, post.id) do %>
                    <div class="mt-4 pt-4 border-t border-slate-100">
                      <div class="space-y-3 mb-4">
                        <%= for comment <- Map.get(post, :comments, []) do %>
                          <div class="flex items-start gap-3 bg-slate-50 p-3 rounded-xl">
                            <div class="flex-shrink-0">
                              <HeadsUpWeb.Components.UI.Avatar.avatar
                                name={comment.user.name || "U"}
                                src={comment.user.image_path}
                                size={:sm}
                              />
                            </div>
                            <div class="flex-1 min-w-0">
                              <div class="flex items-center justify-between">
                                <span class="text-xs font-bold text-slate-900">
                                  {comment.user.name}
                                </span>
                                <div class="flex items-center gap-2">
                                  <span class="text-xs text-slate-400">
                                    {Calendar.strftime(comment.inserted_at, "%b %d")}
                                  </span>
                                  <%= if @current_user_id == comment.user_id do %>
                                    <button
                                      phx-click="delete_comment"
                                      phx-value-comment-id={comment.id}
                                      phx-value-post-id={post.id}
                                      class="text-slate-400 hover:text-red-600 transition-colors"
                                      title="Delete comment"
                                    >
                                      <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                                    </button>
                                  <% end %>
                                </div>
                              </div>
                              <p class="text-sm text-slate-600 mt-1">{comment.content}</p>
                            </div>
                          </div>
                        <% end %>
                        <%= if Enum.empty?(Map.get(post, :comments, [])) do %>
                          <p class="text-xs text-slate-400 text-center py-3">No comments yet</p>
                        <% end %>
                      </div>

                      <%= if @current_user_id do %>
                        <form phx-submit="add_comment" phx-value-post-id={post.id} class="flex gap-2">
                          <input
                            type="text"
                            name="content"
                            placeholder="Write a comment..."
                            maxlength="500"
                            required
                            class="flex-1 bg-slate-50 border-none rounded-xl px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500"
                          />
                          <button
                            type="submit"
                            class="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl text-xs font-bold"
                          >
                            Post
                          </button>
                        </form>
                      <% else %>
                        <p class="text-xs text-slate-400 text-center">Log in to comment</p>
                      <% end %>
                    </div>
                  <% end %>
                </HeadsUpWeb.Components.UI.Card.card>
              </div>
            </div>
          <% else %>
            <HeadsUpWeb.Components.UI.EmptyState.empty_state
              icon="hero-chat-bubble-left-right"
              title="No posts yet"
              message="Be the first to share an update on this goal!"
            />
          <% end %>
        </div>
      </div>

      <%!-- ===== RIGHT SIDEBAR (Desktop only) ===== --%>
      <aside class="hidden xl:flex w-[420px] flex-shrink-0 border-l border-slate-100 p-8 flex-col gap-10 overflow-y-auto custom-scrollbar bg-white">
        <%!-- Goal Info --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Goal Info</h3>
          <div class="space-y-4">
            <%= if @goal.target_date do %>
              <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-calendar" class="w-7 h-7 text-blue-600" />
                </div>
                <div>
                  <p class="text-xs text-slate-400 font-medium">Target Date</p>
                  <p class="text-lg font-extrabold text-slate-900">
                    {Calendar.strftime(@goal.target_date, "%b %d, %Y")}
                  </p>
                </div>
              </div>
            <% end %>

            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-clipboard-document-list" class="w-7 h-7 text-indigo-500" />
              </div>
              <div>
                <p class="text-xs text-slate-400 font-medium">Steps Completed</p>
                <p class="text-lg font-extrabold text-slate-900">
                  {length(Enum.filter(@goal.goal_steps, & &1.completed))} / {length(@goal.goal_steps)}
                </p>
              </div>
            </div>

            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-chart-bar" class="w-7 h-7 text-green-500" />
              </div>
              <div>
                <p class="text-xs text-slate-400 font-medium">Progress</p>
                <p class="text-lg font-extrabold text-slate-900">{@goal.progress}%</p>
              </div>
            </div>
          </div>
        </section>

        <%!-- Goal Creator --%>
        <%= if @goal.user do %>
          <section>
            <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Creator</h3>
            <div class="p-5 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-4 mb-4">
                <HeadsUpWeb.Components.UI.Avatar.avatar
                  name={@goal.user.name || "User"}
                  src={@goal.user.image_path}
                  size={:xl}
                />
                <div>
                  <p class="font-extrabold text-slate-900 text-lg">{@goal.user.name}</p>
                  <p class="text-slate-400 text-sm">@{@goal.user.user_name}</p>
                </div>
              </div>
              <%= if @goal.user.bio do %>
                <p class="text-slate-500 text-sm mb-4">{@goal.user.bio}</p>
              <% end %>
              <div class="grid grid-cols-2 gap-4">
                <div class="text-center p-3 bg-white rounded-xl">
                  <p class="text-xl font-extrabold text-slate-900">{@goal.user.level}</p>
                  <p class="text-xs text-slate-400 font-medium">Level</p>
                </div>
                <div class="text-center p-3 bg-white rounded-xl">
                  <p class="text-xl font-extrabold text-slate-900">{@goal.user.goal_amount}</p>
                  <p class="text-xs text-slate-400 font-medium">Goals</p>
                </div>
              </div>
            </div>
          </section>
        <% end %>

        <%!-- Support This Goal --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Support</h3>
          <div class="space-y-3">
            <%= if @is_owner do %>
              <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
                <div class="w-14 h-14 bg-red-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-heart" class="w-7 h-7 text-red-500" />
                </div>
                <div>
                  <p class="text-lg font-extrabold text-slate-900">{@goal.like_count}</p>
                  <p class="text-xs text-slate-400 font-medium">Likes</p>
                </div>
              </div>
              <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-eye" class="w-7 h-7 text-blue-500" />
                </div>
                <div>
                  <p class="text-lg font-extrabold text-slate-900">{@goal.subscriber_count}</p>
                  <p class="text-xs text-slate-400 font-medium">Subscribers</p>
                </div>
              </div>
            <% else %>
              <button
                phx-click="toggle_like"
                class={"flex items-center gap-4 p-5 rounded-2xl w-full transition-colors #{if @user_liked, do: "bg-red-50 hover:bg-red-100", else: "bg-slate-50 hover:bg-slate-100"}"}
              >
                <div class={"w-14 h-14 rounded-xl flex items-center justify-center #{if @user_liked, do: "bg-red-100", else: "bg-red-50"}"}>
                  <%= if @user_liked do %>
                    <.icon name="hero-heart-solid" class="w-7 h-7 text-red-500" />
                  <% else %>
                    <.icon name="hero-heart" class="w-7 h-7 text-red-500" />
                  <% end %>
                </div>
                <div class="text-left">
                  <p class="text-lg font-extrabold text-slate-900">{@goal.like_count}</p>
                  <p class="text-xs text-slate-400 font-medium">
                    {if @user_liked, do: "Liked", else: "Like this goal"}
                  </p>
                </div>
              </button>
              <button
                phx-click="toggle_subscribe"
                class={"flex items-center gap-4 p-5 rounded-2xl w-full transition-colors #{if @user_subscribed, do: "bg-blue-50 hover:bg-blue-100", else: "bg-slate-50 hover:bg-slate-100"}"}
              >
                <div class={"w-14 h-14 rounded-xl flex items-center justify-center #{if @user_subscribed, do: "bg-blue-100", else: "bg-blue-50"}"}>
                  <%= if @user_subscribed do %>
                    <.icon name="hero-eye-solid" class="w-7 h-7 text-blue-500" />
                  <% else %>
                    <.icon name="hero-eye" class="w-7 h-7 text-blue-500" />
                  <% end %>
                </div>
                <div class="text-left">
                  <p class="text-lg font-extrabold text-slate-900">{@goal.subscriber_count}</p>
                  <p class="text-xs text-slate-400 font-medium">
                    {if @user_subscribed, do: "Subscribed", else: "Subscribe"}
                  </p>
                </div>
              </button>
            <% end %>
            <%= if @goal.privacy == :public do %>
              <button
                id="share-goal-link"
                phx-hook="CopyToClipboard"
                data-url={url(~p"/goals/#{@goal.id}")}
                class="flex items-center gap-4 p-5 bg-slate-50 hover:bg-emerald-50 rounded-2xl w-full transition-colors"
              >
                <div class="w-14 h-14 bg-emerald-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-share" class="w-7 h-7 text-emerald-500" />
                </div>
                <div class="text-left">
                  <p class="text-sm font-extrabold text-slate-900" data-label>Share Goal</p>
                  <p class="text-xs text-slate-400 font-medium">Copy link to clipboard</p>
                </div>
              </button>
            <% end %>
            <%= if @current_user_id && !@is_owner do %>
              <button
                phx-click="show_report_modal"
                phx-value-type="goal"
                phx-value-id={@goal.id}
                class="flex items-center gap-4 p-5 bg-slate-50 hover:bg-red-50 rounded-2xl w-full transition-colors"
              >
                <div class="w-14 h-14 bg-red-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-flag" class="w-7 h-7 text-red-400" />
                </div>
                <div class="text-left">
                  <p class="text-sm font-extrabold text-slate-900">Report Goal</p>
                  <p class="text-xs text-slate-400 font-medium">Flag inappropriate content</p>
                </div>
              </button>
            <% end %>
          </div>
        </section>

        <%!-- Timeline --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Timeline</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4">
              <div class="w-3 h-3 bg-blue-500 rounded-full flex-shrink-0"></div>
              <div>
                <p class="text-sm font-bold text-slate-900">Goal Created</p>
                <p class="text-xs text-slate-400">
                  {Calendar.strftime(@goal.inserted_at, "%b %d, %Y")}
                </p>
              </div>
            </div>
            <%= if @goal.updated_at != @goal.inserted_at do %>
              <div class="flex items-center gap-4">
                <div class="w-3 h-3 bg-green-500 rounded-full flex-shrink-0"></div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Last Updated</p>
                  <p class="text-xs text-slate-400">
                    {Calendar.strftime(@goal.updated_at, "%b %d, %Y")}
                  </p>
                </div>
              </div>
            <% end %>
            <%= if @goal.status == :failed && @goal.failed_at && @goal.failure_reason do %>
              <div class="flex items-start gap-4">
                <div class="w-3 h-3 bg-red-500 rounded-full flex-shrink-0 mt-1"></div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Goal Failed</p>
                  <p class="text-xs text-slate-400 mb-2">
                    {Calendar.strftime(@goal.failed_at, "%b %d, %Y")}
                  </p>
                  <div class="p-3 bg-red-50 rounded-xl">
                    <p class="text-xs text-red-700">{@goal.failure_reason}</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </section>
      </aside>
    </div>

    <%!-- Failure Modal --%>
    <%!-- Report Modal --%>
    <%= if @show_report_modal do %>
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-[32px] shadow-2xl max-w-md w-full p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-flag" class="w-6 h-6 text-red-500" />
            </div>
            <h3 class="text-xl font-extrabold text-slate-900">
              Report {if @report_target_type == "goal", do: "Goal", else: "Post"}
            </h3>
          </div>

          <p class="text-sm text-slate-500 mb-6">
            Help us keep the community safe. Select a reason for your report.
          </p>

          <form phx-submit="submit_report">
            <div class="mb-4">
              <label class="block text-sm font-bold text-slate-700 mb-3">Reason *</label>
              <div class="space-y-2">
                <%= for reason <- HeadsUp.Reports.Report.reasons() do %>
                  <label class={"flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-colors #{if @report_reason == reason, do: "bg-red-50 ring-2 ring-red-200", else: "bg-slate-50 hover:bg-slate-100"}"}>
                    <input
                      type="radio"
                      name="report_reason"
                      value={reason}
                      checked={@report_reason == reason}
                      phx-click="update_report_reason"
                      phx-value-report_reason={reason}
                      class="text-red-500 focus:ring-red-500"
                    />
                    <span class="text-sm font-medium text-slate-700 capitalize">{reason}</span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="mb-6">
              <label for="report_description" class="block text-sm font-bold text-slate-700 mb-2">
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
                class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-red-500 resize-none"
              ><%= @report_description %></textarea>
              <div class="text-xs text-slate-400 mt-1 text-right">
                {String.length(@report_description)}/500
              </div>
            </div>

            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="hide_report_modal"
                class="px-5 py-3 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={@report_reason == ""}
                class="px-5 py-3 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Submit Report
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>

    <%= if @show_fail_modal do %>
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-[32px] shadow-2xl max-w-md w-full p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 bg-amber-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-amber-600" />
            </div>
            <h3 class="text-xl font-extrabold text-slate-900">Mark Goal as Failed</h3>
          </div>

          <p class="text-sm text-slate-500 mb-6">
            Please provide a reason. This helps you learn for future goals.
          </p>

          <form phx-submit="fail_goal">
            <div class="mb-6">
              <label for="failure_reason" class="block text-sm font-bold text-slate-700 mb-2">
                Failure Reason *
              </label>
              <textarea
                id="failure_reason"
                name="failure_reason"
                rows="4"
                value={@failure_reason}
                phx-change="update_failure_reason"
                placeholder="What happened..."
                maxlength="500"
                required
                class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-amber-500 resize-none"
              ><%= @failure_reason %></textarea>
              <div class="text-xs text-slate-400 mt-1 text-right">
                {String.length(@failure_reason)}/500
              </div>
            </div>

            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="hide_fail_modal"
                class="px-5 py-3 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={String.trim(@failure_reason) == ""}
                class="px-5 py-3 bg-amber-500 text-white rounded-xl text-sm font-bold hover:bg-amber-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Mark as Failed
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end
