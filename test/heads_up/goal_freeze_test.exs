defmodule HeadsUp.GoalFreezeTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goals.GoalPost}
  import HeadsUp.AuthFixtures

  describe "goal freeze functionality" do
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

    test "goal owner can freeze their goal", %{goal: goal, goal_owner: goal_owner} do
      assert {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)
      assert frozen_goal.status == :frozen
      assert frozen_goal.is_frozen == true
    end

    test "goal owner can unfreeze their goal", %{goal: goal, goal_owner: goal_owner} do
      # First freeze the goal
      {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)
      assert frozen_goal.status == :frozen

      # Then unfreeze it
      assert {:ok, unfrozen_goal} = Goals.unfreeze_goal_with_ownership(frozen_goal, goal_owner.id)
      assert unfrozen_goal.status == :active
      assert unfrozen_goal.is_frozen == false
    end

    test "non-goal-owner cannot freeze others' goals", %{goal: goal, other_user: other_user} do
      assert {:error, :unauthorized} = Goals.freeze_goal_with_ownership(goal, other_user.id)
    end

    test "non-goal-owner cannot unfreeze others' goals", %{
      goal: goal,
      goal_owner: goal_owner,
      other_user: other_user
    } do
      # First freeze the goal as owner
      {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)

      # Try to unfreeze as non-owner
      assert {:error, :unauthorized} =
               Goals.unfreeze_goal_with_ownership(frozen_goal, other_user.id)
    end

    test "freezing a goal sets both status and is_frozen flag", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)

      assert frozen_goal.status == :frozen
      assert frozen_goal.is_frozen == true
    end

    test "unfreezing a goal resets status to active and is_frozen to false", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      # Freeze then unfreeze
      {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)
      {:ok, unfrozen_goal} = Goals.unfreeze_goal_with_ownership(frozen_goal, goal_owner.id)

      assert unfrozen_goal.status == :active
      assert unfrozen_goal.is_frozen == false
    end

    test "can freeze and unfreeze multiple times", %{goal: goal, goal_owner: goal_owner} do
      # First cycle
      {:ok, frozen_goal_1} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)
      assert frozen_goal_1.status == :frozen

      {:ok, unfrozen_goal_1} = Goals.unfreeze_goal_with_ownership(frozen_goal_1, goal_owner.id)
      assert unfrozen_goal_1.status == :active

      # Second cycle
      {:ok, frozen_goal_2} = Goals.freeze_goal_with_ownership(unfrozen_goal_1, goal_owner.id)
      assert frozen_goal_2.status == :frozen

      {:ok, unfrozen_goal_2} = Goals.unfreeze_goal_with_ownership(frozen_goal_2, goal_owner.id)
      assert unfrozen_goal_2.status == :active
    end
  end

  describe "goal freeze edge cases" do
    setup do
      goal_owner = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, completed_goal} =
        Goals.create_goal(%{
          title: "Completed Goal",
          description: "Test goal",
          status: :completed,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{completed_goal: completed_goal, goal_owner: goal_owner, group: group}
    end

    test "can freeze completed goals", %{completed_goal: goal, goal_owner: goal_owner} do
      assert {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)
      assert frozen_goal.status == :frozen
      assert frozen_goal.is_frozen == true
    end

    test "unfreezing completed goal sets status to active", %{
      completed_goal: goal,
      goal_owner: goal_owner
    } do
      # Freeze the completed goal
      {:ok, frozen_goal} = Goals.freeze_goal_with_ownership(goal, goal_owner.id)

      # Unfreeze should set it to active (not back to completed)
      {:ok, unfrozen_goal} = Goals.unfreeze_goal_with_ownership(frozen_goal, goal_owner.id)
      assert unfrozen_goal.status == :active
      assert unfrozen_goal.is_frozen == false
    end
  end
end
