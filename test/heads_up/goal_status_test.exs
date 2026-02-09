defmodule HeadsUp.GoalStatusTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goal}
  import HeadsUp.AuthFixtures

  describe "goal status enum" do
    test "allows all valid status values" do
      user = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      # Test each status value
      valid_statuses = [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted]

      for status <- valid_statuses do
        attrs = %{
          title: "Test Goal #{status}",
          description: "Test goal",
          status: status,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        }

        # Add failure_reason for failed status
        attrs =
          if status == :failed do
            Map.put(attrs, :failure_reason, "Test failure reason")
          else
            attrs
          end

        assert {:ok, goal} = Goals.create_goal(attrs)
        assert goal.status == status
      end
    end

    test "requires failure_reason when status is failed" do
      user = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      # Should fail without failure_reason
      attrs = %{
        title: "Failed Goal",
        description: "Test goal",
        status: :failed,
        user_id: user.id,
        group_id: group.id,
        target_date: DateTime.add(DateTime.utc_now(), 30, :day)
      }

      assert {:error, changeset} = Goals.create_goal(attrs)
      assert "is required when goal is marked as failed" in errors_on(changeset).failure_reason

      # Should succeed with failure_reason
      attrs_with_reason = Map.put(attrs, :failure_reason, "Ran out of time")
      assert {:ok, goal} = Goals.create_goal(attrs_with_reason)
      assert goal.status == :failed
      assert goal.failure_reason == "Ran out of time"
    end

    test "sets failed_at timestamp when status changes to failed" do
      user = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      # Create active goal
      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          status: :active,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      assert goal.failed_at == nil

      # Update to failed status
      {:ok, updated_goal} =
        Goals.update_goal(goal, %{
          status: :failed,
          failure_reason: "Changed my mind",
          failed_at: DateTime.utc_now()
        })

      assert updated_goal.status == :failed
      assert updated_goal.failure_reason == "Changed my mind"
      assert updated_goal.failed_at != nil
    end

    test "sets deleted_at timestamp for soft deletion" do
      user = user_fixture()

      {:ok, group} =
        HeadsUp.Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      # Create active goal
      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          status: :active,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      assert goal.deleted_at == nil

      # Soft delete the goal
      {:ok, deleted_goal} =
        Goals.update_goal(goal, %{
          status: :deleted,
          deleted_at: DateTime.utc_now()
        })

      assert deleted_goal.status == :deleted
      assert deleted_goal.deleted_at != nil
    end
  end

  describe "goal status transitions" do
    setup do
      user = user_fixture()

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
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{goal: goal, user: user, group: group}
    end

    test "can transition from active to frozen", %{goal: goal} do
      {:ok, frozen_goal} = Goals.update_goal(goal, %{status: :frozen})
      assert frozen_goal.status == :frozen
    end

    test "can transition from frozen to active", %{goal: goal} do
      # First freeze the goal
      {:ok, frozen_goal} = Goals.update_goal(goal, %{status: :frozen})

      # Then unfreeze it
      {:ok, active_goal} = Goals.update_goal(frozen_goal, %{status: :active})
      assert active_goal.status == :active
    end

    test "can transition from active to failed with reason", %{goal: goal} do
      {:ok, failed_goal} =
        Goals.update_goal(goal, %{
          status: :failed,
          failure_reason: "Lost motivation",
          failed_at: DateTime.utc_now()
        })

      assert failed_goal.status == :failed
      assert failed_goal.failure_reason == "Lost motivation"
      assert failed_goal.failed_at != nil
    end

    test "can soft delete a goal", %{goal: goal} do
      {:ok, deleted_goal} =
        Goals.update_goal(goal, %{
          status: :deleted,
          deleted_at: DateTime.utc_now()
        })

      assert deleted_goal.status == :deleted
      assert deleted_goal.deleted_at != nil
    end
  end
end
