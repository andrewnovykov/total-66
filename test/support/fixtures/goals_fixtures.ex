defmodule HeadsUp.GoalsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.Goals` context.
  """

  alias HeadsUp.{Goals, Group}

  def valid_goal_attributes(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    Enum.into(attrs, %{
      title: "Test Goal #{unique_id}",
      description: "A test goal description #{unique_id}",
      privacy: :public,
      status: :active,
      target_date: DateTime.add(DateTime.utc_now(), 30, :day)
    })
  end

  def goal_fixture(attrs \\ %{}) do
    # Ensure we have required associations
    attrs =
      attrs
      |> ensure_user_id()
      |> ensure_group_id()

    {:ok, goal} =
      attrs
      |> valid_goal_attributes()
      |> Goals.create_goal()

    goal
  end

  def valid_goal_post_attributes(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    Enum.into(attrs, %{
      content: "Test post content #{unique_id}",
      post_type: :update
    })
  end

  def goal_post_fixture(attrs \\ %{}) do
    # Ensure we have required associations
    attrs =
      attrs
      |> ensure_user_id()
      |> ensure_goal_id()

    {:ok, post} =
      attrs
      |> valid_goal_post_attributes()
      |> Goals.create_goal_post()

    post
  end

  defp ensure_user_id(attrs) do
    if Map.has_key?(attrs, :user_id) do
      attrs
    else
      user = HeadsUp.AuthFixtures.user_fixture()
      Map.put(attrs, :user_id, user.id)
    end
  end

  defp ensure_group_id(attrs) do
    if Map.has_key?(attrs, :group_id) do
      attrs
    else
      group = HeadsUp.GroupsFixtures.group_fixture()
      Map.put(attrs, :group_id, group.id)
    end
  end

  defp ensure_goal_id(attrs) do
    if Map.has_key?(attrs, :goal_id) do
      attrs
    else
      goal = goal_fixture()
      Map.put(attrs, :goal_id, goal.id)
    end
  end
end
