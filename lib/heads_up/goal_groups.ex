defmodule HeadsUp.GoalGroups do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.{Group, Goals, Users}

  # Admin-only functions
  def create_group_with_admin_check(attrs, user_id) do
    user = Repo.get(Users, user_id)

    if user && user.role == "admin" do
      create_group(attrs)
    else
      {:error, :unauthorized}
    end
  end

  def update_group_with_admin_check(%Group{} = group, attrs, user_id) do
    user = Repo.get(Users, user_id)

    if user && user.role == "admin" do
      update_group(group, attrs)
    else
      {:error, :unauthorized}
    end
  end

  def delete_group_with_admin_check(%Group{} = group, user_id) do
    user = Repo.get(Users, user_id)

    if user && user.role == "admin" do
      delete_group(group)
    else
      {:error, :unauthorized}
    end
  end

  # Regular CRUD functions
  def create_group(attrs) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def get_group(id) do
    Repo.get(Group, id)
  end

  def get_group!(id) do
    Repo.get!(Group, id)
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  def list_groups do
    Repo.all(Group)
    |> Repo.preload([:parent, :subcategories])
  end

  def list_main_categories do
    from(g in Group, where: is_nil(g.parent_id))
    |> Repo.all()
    |> Repo.preload([:subcategories])
  end

  def list_subcategories(parent_id) do
    from(g in Group, where: g.parent_id == ^parent_id)
    |> Repo.all()
  end

  def get_goal_groups do
    groups = Repo.all(Group)
    group_ids = Enum.map(groups, & &1.id)
    counts_map = Goals.get_group_goal_counts(group_ids)

    Enum.map(groups, fn group ->
      goal_counts = Map.get(counts_map, group.id)
      Map.merge(group, goal_counts)
    end)
  end

  def get_goal_groups_with_goals do
    Repo.all(Group)
    |> Repo.preload(:goals)
  end

  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end
end
