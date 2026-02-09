defmodule HeadsUp.GroupsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.GoalGroups` context.
  """

  alias HeadsUp.GoalGroups

  def valid_group_attributes(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    Enum.into(attrs, %{
      name: "Test Group #{unique_id}",
      description: "A test group description #{unique_id}",
      status: "published",
      image_path: "/images/test-group.jpg"
    })
  end

  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> valid_group_attributes()
      |> GoalGroups.create_group()

    group
  end

  def subcategory_fixture(parent, attrs \\ %{}) do
    attrs = Map.put(attrs, :parent_id, parent.id)
    group_fixture(attrs)
  end
end
