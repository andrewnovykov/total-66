defmodule HeadsUp.Groups do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Group

  def list_groups do
    Repo.all(Group)
  end

  def list_published_groups do
    from(g in Group, where: g.status == :published)
    |> Repo.all()
  end

  def get_group!(id), do: Repo.get!(Group, id)

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  @doc """
  Safely deletes a group only if it has no associated goals.
  Returns {:error, :has_goals, count} if the group has goals.
  """
  def safe_delete_group(%Group{} = group) do
    goal_count = count_goals_in_group(group.id)

    if goal_count > 0 do
      {:error, :has_goals, goal_count}
    else
      delete_group(group)
    end
  end

  @doc """
  Returns the count of goals associated with a group.
  """
  def count_goals_in_group(group_id) do
    from(g in HeadsUp.Goal, where: g.group_id == ^group_id, select: count(g.id))
    |> Repo.one()
  end

  @doc """
  Returns a map of goal counts for multiple groups in a single query.
  Solves the N+1 query problem when displaying goal counts for a list of groups.

  ## Example
      iex> goal_counts_by_group_ids([1, 2, 3])
      %{1 => 5, 2 => 0, 3 => 12}
  """
  def goal_counts_by_group_ids(group_ids) when is_list(group_ids) do
    from(g in HeadsUp.Goal,
      where: g.group_id in ^group_ids,
      group_by: g.group_id,
      select: {g.group_id, count(g.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Checks if a group has any associated goals.
  Uses EXISTS query which stops at first match (more efficient than COUNT).
  """
  def has_goals?(%Group{} = group), do: has_goals?(group.id)

  def has_goals?(group_id) when is_integer(group_id) do
    from(g in HeadsUp.Goal, where: g.group_id == ^group_id)
    |> Repo.exists?()
  end

  @doc """
  Gets a group by id, returns nil if not found.
  """
  def get_group(id), do: Repo.get(Group, id)

  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end
end
