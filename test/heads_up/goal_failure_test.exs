defmodule HeadsUp.GoalFailureTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.Goals
  import HeadsUp.AuthFixtures

  describe "goal failure functionality" do
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

    test "goal owner can fail their goal with a reason", %{goal: goal, goal_owner: goal_owner} do
      failure_reason = "Could not allocate enough time due to work commitments"

      assert {:ok, failed_goal} =
               Goals.fail_goal_with_ownership(goal, failure_reason, goal_owner.id)

      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == failure_reason
      assert not is_nil(failed_goal.failed_at)
    end

    test "goal owner cannot fail goal without providing a reason", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      assert {:error, changeset} = Goals.fail_goal_with_ownership(goal, "", goal_owner.id)

      assert %{failure_reason: ["is required when goal is marked as failed"]} =
               errors_on(changeset)
    end

    test "goal owner cannot fail goal with nil reason", %{goal: goal, goal_owner: goal_owner} do
      # This should trigger a FunctionClauseError since the function expects a binary
      assert_raise FunctionClauseError, fn ->
        Goals.fail_goal_with_ownership(goal, nil, goal_owner.id)
      end
    end

    test "non-goal-owner cannot fail others' goals", %{goal: goal, other_user: other_user} do
      failure_reason = "Test failure reason"

      assert {:error, :unauthorized} =
               Goals.fail_goal_with_ownership(goal, failure_reason, other_user.id)
    end

    test "failing a goal sets status, failure_reason, and failed_at timestamp", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      failure_reason = "Lost motivation after initial setbacks"
      {:ok, failed_goal} = Goals.fail_goal_with_ownership(goal, failure_reason, goal_owner.id)

      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == failure_reason
      assert not is_nil(failed_goal.failed_at)
      # Just check that failed_at is recent (within last minute)
      time_diff = DateTime.diff(DateTime.utc_now(), failed_goal.failed_at, :second)
      assert time_diff >= 0 and time_diff < 60
    end

    test "can fail different types of goals", %{goal_owner: goal_owner, group: group} do
      # Test failing a completed goal
      {:ok, completed_goal} =
        Goals.create_goal(%{
          title: "Completed Goal",
          description: "Test goal",
          status: :completed,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      failure_reason = "Realized the completion was not actually achieved"

      assert {:ok, failed_goal} =
               Goals.fail_goal_with_ownership(completed_goal, failure_reason, goal_owner.id)

      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == failure_reason

      # Test failing a frozen goal
      {:ok, frozen_goal} =
        Goals.create_goal(%{
          title: "Frozen Goal",
          description: "Test goal",
          status: :frozen,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      failure_reason = "Decided to abandon this goal permanently"

      assert {:ok, failed_goal} =
               Goals.fail_goal_with_ownership(frozen_goal, failure_reason, goal_owner.id)

      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == failure_reason
    end

    test "can update failure information for already failed goal", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      # First, fail the goal
      failure_reason = "Initial failure reason"
      {:ok, failed_goal} = Goals.fail_goal_with_ownership(goal, failure_reason, goal_owner.id)

      # Add a small delay to ensure different timestamps
      :timer.sleep(10)

      # Try to fail it again with different reason
      new_failure_reason = "Updated failure reason with more details"

      assert {:ok, updated_goal} =
               Goals.fail_goal_with_ownership(failed_goal, new_failure_reason, goal_owner.id)

      # Should update the failure reason and timestamp
      assert updated_goal.status == :failed
      assert updated_goal.failure_reason == new_failure_reason
      # Check that failed_at was updated (should be later than original)
      assert DateTime.compare(updated_goal.failed_at, failed_goal.failed_at) in [:gt, :eq]
    end

    test "failure reason validation requires non-empty string", %{
      goal: goal,
      goal_owner: goal_owner
    } do
      # Test with whitespace only
      assert {:error, changeset} = Goals.fail_goal_with_ownership(goal, "   ", goal_owner.id)

      assert %{failure_reason: ["is required when goal is marked as failed"]} =
               errors_on(changeset)
    end

    test "failure reason can be long text", %{goal: goal, goal_owner: goal_owner} do
      long_reason =
        String.duplicate("This is a detailed explanation of why the goal failed. ", 10)

      assert {:ok, failed_goal} = Goals.fail_goal_with_ownership(goal, long_reason, goal_owner.id)
      assert failed_goal.failure_reason == long_reason
    end
  end

  describe "goal failure direct functions" do
    setup do
      goal_owner = user_fixture()

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

      %{goal: goal, goal_owner: goal_owner, group: group}
    end

    test "fail_goal function works correctly", %{goal: goal} do
      failure_reason = "Direct function test failure"

      assert {:ok, failed_goal} = Goals.fail_goal(goal, failure_reason)
      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == failure_reason
      assert not is_nil(failed_goal.failed_at)
    end

    test "fail_goal function validates failure reason", %{goal: goal} do
      assert {:error, changeset} = Goals.fail_goal(goal, "")

      assert %{failure_reason: ["is required when goal is marked as failed"]} =
               errors_on(changeset)
    end
  end
end
