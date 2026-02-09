defmodule HeadsUpWeb.Api.ChallengeController do
  use HeadsUpWeb, :controller

  alias HeadsUp.{Challenges, Repo}

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/challenges - List public challenges/templates
  def index(conn, params) do
    current_user_id = get_current_user_id(conn)

    challenges =
      if current_user_id do
        Challenges.list_visible_challenges(current_user_id)
      else
        Challenges.list_public_challenges()
      end
      |> Repo.preload([:creator, :participants])
      |> paginate(params)

    conn
    |> put_status(:ok)
    |> render(:index, challenges: challenges, current_user_id: current_user_id)
  end

  # GET /api/challenges/templates - List all templates
  def templates(conn, params) do
    templates =
      Challenges.list_templates()
      |> Repo.preload([:creator, :participants])
      |> paginate(params)

    conn
    |> put_status(:ok)
    |> render(:index, challenges: templates, current_user_id: get_current_user_id(conn))
  end

  # GET /api/challenges/my - My challenges (participating)
  def my_challenges(conn, params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      challenges =
        Challenges.list_my_challenges(current_user_id)
        |> Repo.preload([:creator, :participants])
        |> paginate(params)

      conn
      |> put_status(:ok)
      |> render(:index, challenges: challenges, current_user_id: current_user_id)
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/challenges/:id - Show challenge
  def show(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(id) do
      {challenge_id, _} ->
        case Challenges.get_challenge(challenge_id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

          challenge ->
            challenge =
              Repo.preload(challenge, [
                :creator,
                :participants,
                tasks: :completions
              ])

            participant =
              if current_user_id,
                do: Challenges.get_participant(challenge_id, current_user_id),
                else: nil

            conn
            |> put_status(:ok)
            |> render(:show,
              challenge: challenge,
              current_user_id: current_user_id,
              participant: participant
            )
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
    end
  end

  # POST /api/challenges - Create challenge
  def create(conn, %{"challenge" => challenge_params}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Challenges.create_challenge(challenge_params, current_user) do
        {:ok, challenge} ->
          challenge =
            Repo.preload(challenge, [
              :creator,
              :participants,
              tasks: :completions
            ])

          conn
          |> put_status(:created)
          |> render(:show,
            challenge: challenge,
            current_user_id: current_user.id,
            participant: nil
          )

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:changeset_error, changeset: changeset)
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # PUT /api/challenges/:id - Update challenge
  def update(conn, %{"id" => id, "challenge" => challenge_params}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_challenge(challenge_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            challenge ->
              case Challenges.update_challenge(challenge, challenge_params, current_user.id) do
                {:ok, updated} ->
                  updated =
                    Repo.preload(updated, [
                      :creator,
                      :participants,
                      tasks: :completions
                    ])

                  conn
                  |> put_status(:ok)
                  |> render(:show,
                    challenge: updated,
                    current_user_id: current_user.id,
                    participant: nil
                  )

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only update your own challenges")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/challenges/:id - Delete challenge
  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_challenge(challenge_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            challenge ->
              case Challenges.delete_challenge(challenge, current_user.id) do
                {:ok, _} ->
                  conn |> put_status(:ok) |> render(:action_success, message: "Challenge deleted")

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only delete your own challenges")

                {:error, _} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Failed to delete challenge")
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/start - Start challenge from template
  def start(conn, %{"id" => id} = params) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {template_id, _} ->
          case Challenges.get_challenge(template_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            template ->
              start_date =
                case params["start_date"] do
                  nil ->
                    Date.utc_today()

                  date_str ->
                    case Date.from_iso8601(date_str) do
                      {:ok, date} -> date
                      _ -> Date.utc_today()
                    end
                end

              case Challenges.start_challenge_from_template(
                     template.id,
                     current_user.id,
                     start_date
                   ) do
                {:ok, challenge} ->
                  challenge =
                    Repo.preload(challenge, [
                      :creator,
                      :participants,
                      tasks: :completions
                    ])

                  participant = Challenges.get_participant(challenge.id, current_user.id)

                  conn
                  |> put_status(:created)
                  |> render(:show,
                    challenge: challenge,
                    current_user_id: current_user.id,
                    participant: participant
                  )

                {:error, :not_a_template} ->
                  conn
                  |> put_status(:bad_request)
                  |> render(:error, message: "This challenge is not a template")

                {:error, :already_started} ->
                  conn
                  |> put_status(:conflict)
                  |> render(:error, message: "You already started this challenge")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/join - Join challenge
  def join(conn, %{"id" => id} = params) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_challenge(challenge_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            challenge ->
              start_date = params["start_date"] || Date.to_iso8601(Date.utc_today())

              case Challenges.join_challenge(challenge.id, current_user.id,
                     start_date: start_date
                   ) do
                {:ok, participant} ->
                  conn |> put_status(:ok) |> render(:participant, participant: participant)

                {:error, :already_joined} ->
                  conn
                  |> put_status(:conflict)
                  |> render(:error, message: "Already joined this challenge")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/challenges/:id/leave - Leave challenge
  def leave(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.leave_challenge(challenge_id, current_user.id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Left challenge")

            {:error, reason} when reason in [:not_participating, :not_found] ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Not participating in this challenge")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to leave challenge")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/fail - Fail challenge
  def fail(conn, %{"id" => id, "reason" => reason}) when is_binary(reason) and reason != "" do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_challenge(challenge_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            challenge ->
              case Challenges.fail_challenge(challenge.id, current_user.id, reason) do
                {:ok, updated} ->
                  updated =
                    Repo.preload(updated, [
                      :creator,
                      :participants,
                      tasks: :completions
                    ])

                  conn
                  |> put_status(:ok)
                  |> render(:show,
                    challenge: updated,
                    current_user_id: current_user.id,
                    participant: nil
                  )

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only fail your own challenges")

                {:error, _} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Failed to mark challenge as failed")
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  def fail(conn, _params) do
    conn |> put_status(:bad_request) |> render(:error, message: "Failure reason is required")
  end

  # POST /api/challenges/:id/cancel - Cancel challenge
  def cancel(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.cancel_challenge(challenge_id, current_user.id) do
            {:ok, updated} ->
              updated =
                Repo.preload(updated, [
                  :creator,
                  :participants,
                  tasks: :completions
                ])

              conn
              |> put_status(:ok)
              |> render(:show,
                challenge: updated,
                current_user_id: current_user.id,
                participant: Challenges.get_participant(challenge_id, current_user.id)
              )

            {:error, :unauthorized} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You can only cancel your own challenges")

            {:error, :cannot_cancel_template} ->
              conn
              |> put_status(:bad_request)
              |> render(:error, message: "Cannot cancel a template")

            {:error, :invalid_status} ->
              conn
              |> put_status(:bad_request)
              |> render(:error, message: "Challenge must be active to cancel")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to cancel challenge")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/share - Share as template
  def share(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_challenge(challenge_id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Challenge not found")

            challenge ->
              case Challenges.share_as_template(challenge.id, current_user.id) do
                {:ok, template} ->
                  template =
                    Repo.preload(template, [
                      :creator,
                      :participants,
                      tasks: :completions
                    ])

                  conn
                  |> put_status(:created)
                  |> render(:show,
                    challenge: template,
                    current_user_id: current_user.id,
                    participant: nil
                  )

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only share your own challenges")

                {:error, _} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Failed to share challenge")
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/challenges/:id/progress - Get participant progress
  def progress(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_participant(challenge_id, current_user_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Not participating in this challenge")

            participant ->
              progress = Challenges.get_participant_progress(participant.id)
              conn |> put_status(:ok) |> render(:progress, progress: progress)
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/challenges/:id/today - Today's items for challenge
  def today(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_participant(challenge_id, current_user_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Not participating in this challenge")

            participant ->
              today_items = Challenges.get_today_items(participant.challenge_id, participant.id)
              conn |> put_status(:ok) |> render(:today, today_items: today_items)
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/tasks/:task_id/complete - Complete task
  def complete_task(conn, %{"id" => id, "task_id" => task_id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      with {challenge_id, _} <- Integer.parse(id),
           {tid, _} <- Integer.parse(task_id),
           participant when not is_nil(participant) <-
             Challenges.get_participant(challenge_id, current_user_id) do
        case Challenges.complete_task(participant.id, tid, Date.utc_today()) do
          {:ok, _} ->
            conn |> put_status(:ok) |> render(:action_success, message: "Task completed")

          {:error, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, message: "Failed to complete task")
        end
      else
        nil ->
          conn
          |> put_status(:not_found)
          |> render(:error, message: "Not participating in this challenge")

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/challenges/:id/check-in - Daily check-in
  def check_in(conn, %{"id" => id, "check_in" => check_in_params}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      case Integer.parse(id) do
        {challenge_id, _} ->
          case Challenges.get_participant(challenge_id, current_user.id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Not participating in this challenge")

            participant ->
              # Check auto-fail before allowing check-in
              case Challenges.check_and_auto_fail(participant.id) do
                {:ok, :auto_failed} ->
                  conn
                  |> put_status(:bad_request)
                  |> render(:error,
                    message: "Challenge auto-failed due to 7+ consecutive missed days"
                  )

                _ ->
                  case Challenges.create_daily_check_in(participant.id, check_in_params) do
                    {:ok, check_in} ->
                      check_in =
                        Repo.preload(check_in, [:user, :check_in_likes, :check_in_comments])

                      conn
                      |> put_status(:created)
                      |> render(:check_in, check_in: check_in, current_user_id: current_user.id)

                    {:error, :already_checked_in} ->
                      conn
                      |> put_status(:conflict)
                      |> render(:error, message: "Already checked in for this date")

                    {:error, :date_before_start} ->
                      conn
                      |> put_status(:bad_request)
                      |> render(:error, message: "Cannot check in before challenge start date")

                    {:error, :date_after_end} ->
                      conn
                      |> put_status(:bad_request)
                      |> render(:error, message: "Cannot check in after challenge end date")

                    {:error, :future_date} ->
                      conn
                      |> put_status(:bad_request)
                      |> render(:error, message: "Cannot check in for future dates")

                    {:error, changeset} ->
                      conn
                      |> put_status(:unprocessable_entity)
                      |> render(:changeset_error, changeset: changeset)
                  end
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/challenges/:id/feed - Challenge feed (check-ins)
  def feed(conn, %{"id" => id} = params) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(id) do
      {challenge_id, _} ->
        page = parse_int(params["page"], 1)
        limit = parse_int(params["limit"], 20)

        offset = (page - 1) * limit

        feed =
          Challenges.get_challenge_feed(challenge_id, current_user_id,
            limit: limit,
            offset: offset
          )

        conn |> put_status(:ok) |> render(:feed, feed: feed, current_user_id: current_user_id)

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid challenge ID")
    end
  end

  # POST /api/check-ins/:id/like - Like check-in
  def like_check_in(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {check_in_id, _} ->
          case Challenges.like_check_in(check_in_id, current_user_id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Check-in liked")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to like check-in")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid check-in ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/check-ins/:id/like - Unlike check-in
  def unlike_check_in(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {check_in_id, _} ->
          case Challenges.unlike_check_in(check_in_id, current_user_id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Check-in unliked")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to unlike check-in")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid check-in ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/check-ins/:id/comments - Comment on check-in
  def create_check_in_comment(conn, %{"id" => id, "comment" => comment_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {check_in_id, _} ->
          attrs =
            Map.merge(comment_params, %{
              "check_in_id" => check_in_id,
              "user_id" => current_user_id
            })

          case Challenges.create_check_in_comment(attrs) do
            {:ok, comment} ->
              comment = Repo.preload(comment, :user)
              conn |> put_status(:created) |> render(:check_in_comment, comment: comment)

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:changeset_error, changeset: changeset)
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid check-in ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # Private helpers

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end

  defp paginate(items, params) do
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 20) |> min(100)
    offset = (page - 1) * per_page

    items |> Enum.drop(offset) |> Enum.take(per_page)
  end

  defp parse_int(nil, default), do: default

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_int(_, default), do: default
end
