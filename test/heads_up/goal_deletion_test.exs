defmodule HeadsUp.GoalDeletionTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.Goals
  import HeadsUp.AuthFixtures

  describe "goal soft deletion functionality" do
    setup do
      goal_owner = user_fixture()
      other_user = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          status: :active,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{goal: goal, goal_owner: goal_owner, other_user: other_user, group: group}
    end

    test "goal owner can soft delete their goal", %{goal: goal, goal_owner: goal_owner} do
      assert {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)
      assert deleted_goal.status == :deleted
      assert not is_nil(deleted_goal.deleted_at)
    end

    test "goal owner can restore their deleted goal", %{goal: goal, goal_owner: goal_owner} do
      # First delete the goal
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)
      assert deleted_goal.status == :deleted

      # Then restore it
      assert {:ok, restored_goal} = Goals.restore_goal_with_ownership(deleted_goal, goal_owner.id)
      assert restored_goal.status == :active
      assert is_nil(restored_goal.deleted_at)
    end

    test "non-goal-owner cannot delete others' goals", %{goal: goal, other_user: other_user} do
      assert {:error, :unauthorized} = Goals.soft_delete_goal_with_ownership(goal, other_user.id)
    end

    test "non-goal-owner cannot restore others' goals", %{
      goal: goal,
      goal_owner: goal_owner,
      other_user: other_user
    } do
      # First delete the goal as owner
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)

      # Try to restore as non-owner
      assert {:error, :unauthorized} =
               Goals.restore_goal_with_ownership(deleted_goal, other_user.id)
    end

    test "soft deleting a goal sets status and deleted_at timestamp", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)

      assert deleted_goal.status == :deleted
      assert not is_nil(deleted_goal.deleted_at)
      # Just check that deleted_at is recent (within last minute)
      time_diff = DateTime.diff(DateTime.utc_now(), deleted_goal.deleted_at, :second)
      assert time_diff >= 0 and time_diff < 60
    end

    test "restoring a goal clears deleted_at and sets status to active", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      # Delete then restore
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)
      {:ok, restored_goal} = Goals.restore_goal_with_ownership(deleted_goal, goal_owner.id)

      assert restored_goal.status == :active
      assert is_nil(restored_goal.deleted_at)
    end

    test "can delete and restore multiple times", %{goal: goal, goal_owner: goal_owner} do
      # First cycle
      {:ok, deleted_goal_1} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)
      assert deleted_goal_1.status == :deleted

      {:ok, restored_goal_1} = Goals.restore_goal_with_ownership(deleted_goal_1, goal_owner.id)
      assert restored_goal_1.status == :active

      # Second cycle
      {:ok, deleted_goal_2} =
        Goals.soft_delete_goal_with_ownership(restored_goal_1, goal_owner.id)

      assert deleted_goal_2.status == :deleted

      {:ok, restored_goal_2} = Goals.restore_goal_with_ownership(deleted_goal_2, goal_owner.id)
      assert restored_goal_2.status == :active
    end
  end

  describe "goal filtering with soft deletion" do
    setup do
      goal_owner = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, active_goal} =
        Goals.create_goal(%{
          title: "Active Goal",
          description: "Test goal",
          status: :active,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, goal_to_delete} =
        Goals.create_goal(%{
          title: "Goal To Delete",
          description: "Test goal",
          status: :active,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Delete one goal
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal_to_delete, goal_owner.id)

      %{
        goal_owner: goal_owner,
        group: group,
        active_goal: active_goal,
        deleted_goal: deleted_goal
      }
    end

    test "list_goals_by_user excludes deleted goals", %{
      goal_owner: goal_owner,
      active_goal: active_goal
    } do
      goals = Goals.list_goals_by_user(goal_owner.id)

      assert length(goals) == 1
      assert Enum.any?(goals, &(&1.id == active_goal.id))
    end

    test "list_deleted_goals_by_user only returns deleted goals", %{
      goal_owner: goal_owner,
      deleted_goal: deleted_goal
    } do
      deleted_goals = Goals.list_deleted_goals_by_user(goal_owner.id)

      assert length(deleted_goals) == 1
      assert Enum.any?(deleted_goals, &(&1.id == deleted_goal.id))
    end

    test "list_goals_by_group excludes deleted goals", %{group: group, active_goal: active_goal} do
      goals = Goals.list_goals_by_group(group.id)

      assert length(goals) == 1
      assert Enum.any?(goals, &(&1.id == active_goal.id))
    end

    test "list_public_goals_by_group excludes deleted goals", %{
      group: group,
      active_goal: active_goal
    } do
      goals = Goals.list_public_goals_by_group(group.id)

      assert length(goals) == 1
      assert Enum.any?(goals, &(&1.id == active_goal.id))
    end

    test "after restoring, goal appears in regular lists again", %{
      goal_owner: goal_owner,
      deleted_goal: deleted_goal,
      group: group
    } do
      # Restore the deleted goal
      {:ok, _restored_goal} = Goals.restore_goal_with_ownership(deleted_goal, goal_owner.id)

      # Should now appear in regular lists
      user_goals = Goals.list_goals_by_user(goal_owner.id)
      group_goals = Goals.list_goals_by_group(group.id)

      assert length(user_goals) == 2
      assert length(group_goals) == 2

      # Should not appear in deleted list
      deleted_goals = Goals.list_deleted_goals_by_user(goal_owner.id)
      assert length(deleted_goals) == 0
    end
  end

  describe "goal deletion edge cases" do
    setup do
      goal_owner = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, frozen_goal} =
        Goals.create_goal(%{
          title: "Frozen Goal",
          description: "Test goal",
          status: :frozen,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{frozen_goal: frozen_goal, goal_owner: goal_owner, group: group}
    end

    test "can delete frozen goals", %{frozen_goal: goal, goal_owner: goal_owner} do
      assert {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)
      assert deleted_goal.status == :deleted
      assert not is_nil(deleted_goal.deleted_at)
    end

    test "restoring a deleted frozen goal sets status to active", %{
      frozen_goal: goal,
      goal_owner: goal_owner
    } do
      # Delete the frozen goal
      {:ok, deleted_goal} = Goals.soft_delete_goal_with_ownership(goal, goal_owner.id)

      # Restore should set it to active (not back to frozen)
      {:ok, restored_goal} = Goals.restore_goal_with_ownership(deleted_goal, goal_owner.id)
      assert restored_goal.status == :active
      assert is_nil(restored_goal.deleted_at)
    end
  end
end
