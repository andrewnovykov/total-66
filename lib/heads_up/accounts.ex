defmodule HeadsUp.Accounts do
  alias HeadsUp.Repo
  alias HeadsUp.{Users, UserFollow, Friendship, ActivityService}
  import Ecto.Query

  def create_user(attrs) do
    %Users{}
    |> Users.changeset(attrs)
    |> Repo.insert()
  end

  def list_users do
    from(u in Users, where: u.moderation_status != "hidden")
    |> Repo.all()
  end

  def get_user(id) do
    Repo.get(Users, id)
  end

  def get_user_by_username(username) do
    Repo.get_by(Users, user_name: username)
  end

  def update_user(%Users{} = user, attrs) do
    user
    |> Users.changeset(attrs)
    |> Repo.update()
  end

  # Follow functionality with privacy checks
  def follow_user(follower_id, following_id) do
    # Check if users exist
    follower = Repo.get(Users, follower_id)
    following = Repo.get(Users, following_id)

    cond do
      is_nil(follower) or is_nil(following) ->
        {:error, :user_not_found}

      follower_id == following_id ->
        {:error, :cannot_follow_self}

      following.privacy == "private" ->
        {:error, :user_is_private}

      following.privacy == "friends_only" and not are_friends?(follower_id, following_id) ->
        {:error, :must_be_friends}

      true ->
        result =
          %UserFollow{}
          |> UserFollow.changeset(%{follower_id: follower_id, following_id: following_id})
          |> Repo.insert()

        case result do
          {:ok, follow} ->
            # Track activity for the follower
            ActivityService.track_activity(follower_id, "user_followed",
              follow_id: follow.id,
              description: "Started following #{following.name || following.user_name}"
            )

            # Track activity for the user being followed
            ActivityService.track_activity(following_id, "user_received_follow",
              follow_id: follow.id,
              description: "Gained a new follower: #{follower.name || follower.user_name}"
            )

            {:ok, follow}

          error ->
            error
        end
    end
  end

  def unfollow_user(follower_id, following_id) do
    case Repo.get_by(UserFollow, follower_id: follower_id, following_id: following_id) do
      nil -> {:error, :not_found}
      follow -> Repo.delete(follow)
    end
  end

  def is_following?(follower_id, following_id) do
    Repo.exists?(
      from f in UserFollow,
        where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
  end

  def get_followers_count(user_id) do
    Repo.aggregate(from(f in UserFollow, where: f.following_id == ^user_id), :count, :id)
  end

  def get_following_count(user_id) do
    Repo.aggregate(from(f in UserFollow, where: f.follower_id == ^user_id), :count, :id)
  end

  def get_user_with_stats(user_id) do
    user = get_user(user_id)

    if user do
      user
      |> Map.put(:followers_count, get_followers_count(user_id))
      |> Map.put(:following_count, get_following_count(user_id))
    else
      nil
    end
  end

  # Friendship functions
  def send_friend_request(user_id, friend_id) do
    # Check if users exist
    user = Repo.get(Users, user_id)
    friend = Repo.get(Users, friend_id)

    cond do
      is_nil(user) or is_nil(friend) ->
        {:error, :user_not_found}

      user_id == friend_id ->
        {:error, :cannot_friend_self}

      # Check if friendship already exists in either direction
      friendship_exists?(user_id, friend_id) ->
        {:error, :friendship_already_exists}

      true ->
        %Friendship{}
        |> Friendship.changeset(%{user_id: user_id, friend_id: friend_id, status: "pending"})
        |> Repo.insert()
    end
  end

  def accept_friend_request(user_id, friend_id) do
    # Friend request must be TO the user accepting it
    case get_friend_request(friend_id, user_id) do
      nil ->
        {:error, :request_not_found}

      friendship ->
        if friendship.status == "pending" do
          friendship
          |> Friendship.changeset(%{status: "accepted"})
          |> Repo.update()
        else
          {:error, :request_not_pending}
        end
    end
  end

  def decline_friend_request(user_id, friend_id) do
    # Friend request must be TO the user declining it
    case get_friend_request(friend_id, user_id) do
      nil ->
        {:error, :request_not_found}

      friendship ->
        if friendship.status == "pending" do
          friendship
          |> Friendship.changeset(%{status: "declined"})
          |> Repo.update()
        else
          {:error, :request_not_pending}
        end
    end
  end

  def cancel_friend_request(user_id, friend_id) do
    # User can only cancel requests they sent
    case get_friend_request(user_id, friend_id) do
      nil ->
        {:error, :request_not_found}

      friendship ->
        if friendship.status == "pending" do
          Repo.delete(friendship)
        else
          {:error, :cannot_cancel}
        end
    end
  end

  def remove_friend(user_id, friend_id) do
    # Remove friendship in either direction
    from(f in Friendship,
      where:
        (f.user_id == ^user_id and f.friend_id == ^friend_id) or
          (f.user_id == ^friend_id and f.friend_id == ^user_id),
      where: f.status == "accepted"
    )
    |> Repo.delete_all()

    {:ok, :removed}
  end

  def are_friends?(user_id, friend_id) do
    Repo.exists?(
      from f in Friendship,
        where:
          ((f.user_id == ^user_id and f.friend_id == ^friend_id) or
             (f.user_id == ^friend_id and f.friend_id == ^user_id)) and
            f.status == "accepted"
    )
  end

  def friendship_exists?(user_id, friend_id) do
    Repo.exists?(
      from f in Friendship,
        where:
          (f.user_id == ^user_id and f.friend_id == ^friend_id) or
            (f.user_id == ^friend_id and f.friend_id == ^user_id)
    )
  end

  def get_friend_request(user_id, friend_id) do
    Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id)
  end

  def list_friend_requests(user_id) do
    from(f in Friendship,
      where: f.friend_id == ^user_id and f.status == "pending",
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_sent_friend_requests(user_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.status == "pending",
      preload: [:friend]
    )
    |> Repo.all()
  end

  def list_friends(user_id) do
    from(f in Friendship,
      where:
        (f.user_id == ^user_id or f.friend_id == ^user_id) and
          f.status == "accepted",
      preload: [:user, :friend]
    )
    |> Repo.all()
    |> Enum.map(fn friendship ->
      if friendship.user_id == user_id do
        friendship.friend
      else
        friendship.user
      end
    end)
  end

  def get_friends_count(user_id) do
    Repo.aggregate(
      from(f in Friendship,
        where:
          (f.user_id == ^user_id or f.friend_id == ^user_id) and
            f.status == "accepted"
      ),
      :count,
      :id
    )
  end

  def list_followers(user_id) do
    from(f in UserFollow,
      where: f.following_id == ^user_id,
      preload: [:follower]
    )
    |> Repo.all()
    |> Enum.map(& &1.follower)
  end

  def list_following(user_id) do
    from(f in UserFollow,
      where: f.follower_id == ^user_id,
      preload: [:following]
    )
    |> Repo.all()
    |> Enum.map(& &1.following)
  end

  def remove_follower(user_id, follower_id) do
    # Remove the follower relationship where follower_id follows user_id
    case Repo.get_by(UserFollow, follower_id: follower_id, following_id: user_id) do
      nil -> {:error, :not_found}
      follow -> Repo.delete(follow)
    end
  end
end
