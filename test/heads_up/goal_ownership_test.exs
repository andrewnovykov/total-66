defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goal, GoalStep}
  import HeadsUp.AuthFixtures

  describe "goal ownership validation" do
    setup do
      owner = user_fixture()
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
          user_id: owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{goal: goal, owner: owner, other_user: other_user, group: group}
    end

    test "goal owner can update goal", %{goal: goal, owner: owner} do
      assert {:ok, updated_goal} =
               Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, owner.id)

      assert updated_goal.title == "Updated Title"
    end

    test "non-owner cannot update goal", %{goal: goal, other_user: other_user} do
      assert {:error, :unauthorized} =
               Goals.update_goal_with_ownership(goal, %{title: "Updated Title"}, other_user.id)
    end

    test "goal owner can create goal steps", %{goal: goal, owner: owner} do
      attrs = %{
        title: "Test Step",
        goal_id: goal.id,
        order: 1
      }

      assert {:ok, step} = Goals.create_goal_step_with_ownership(attrs, owner.id)
      assert step.title == "Test Step"
    end

    test "non-owner cannot create goal steps", %{goal: goal, other_user: other_user} do
      attrs = %{
        title: "Test Step",
        goal_id: goal.id,
        order: 1
      }

      assert {:error, :unauthorized} = Goals.create_goal_step_with_ownership(attrs, other_user.id)
    end

    test "goal owner can update goal steps", %{goal: goal, owner: owner} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Original Step",
          goal_id: goal.id,
          order: 1
        })

      assert {:ok, updated_step} =
               Goals.update_goal_step_with_ownership(step, %{title: "Updated Step"}, owner.id)

      assert updated_step.title == "Updated Step"
    end

    test "non-owner cannot update goal steps", %{goal: goal, other_user: other_user} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Original Step",
          goal_id: goal.id,
          order: 1
        })

      assert {:error, :unauthorized} =
               Goals.update_goal_step_with_ownership(
                 step,
                 %{title: "Updated Step"},
                 other_user.id
               )
    end

    test "goal owner can delete goal steps", %{goal: goal, owner: owner} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Step to Delete",
          goal_id: goal.id,
          order: 1
        })

      assert {:ok, _deleted_step} = Goals.delete_goal_step_with_ownership(step, owner.id)
    end

    test "non-owner cannot delete goal steps", %{goal: goal, other_user: other_user} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Step to Delete",
          goal_id: goal.id,
          order: 1
        })

      assert {:error, :unauthorized} = Goals.delete_goal_step_with_ownership(step, other_user.id)
    end

    test "goal owner can toggle step completion", %{goal: goal, owner: owner} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Step to Toggle",
          goal_id: goal.id,
          order: 1,
          completed: false
        })

      assert {:ok, updated_step} =
               Goals.toggle_goal_step_completion_with_ownership(step, owner.id)

      assert updated_step.completed == true
    end

    test "non-owner cannot toggle step completion", %{goal: goal, other_user: other_user} do
      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Step to Toggle",
          goal_id: goal.id,
          order: 1,
          completed: false
        })

      assert {:error, :unauthorized} =
               Goals.toggle_goal_step_completion_with_ownership(step, other_user.id)
    end
  end

  describe "goal step ownership through goal" do
    test "properly loads goal association for ownership check" do
      owner = user_fixture()
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
          user_id: owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Test Step",
          goal_id: goal.id,
          order: 1
        })

      # Test that the step properly loads the goal for ownership validation
      fresh_step = Goals.get_goal_step!(step.id)

      # Owner can update
      assert {:ok, _} =
               Goals.update_goal_step_with_ownership(fresh_step, %{title: "Updated"}, owner.id)

      # Non-owner cannot update
      assert {:error, :unauthorized} =
               Goals.update_goal_step_with_ownership(
                 fresh_step,
                 %{title: "Updated"},
                 other_user.id
               )
    end
  end
end
