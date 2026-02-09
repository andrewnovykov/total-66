defmodule HeadsUp.PostOwnershipTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Goals.GoalPost}
  import HeadsUp.AuthFixtures

  describe "post ownership validation" do
    setup do
      goal_owner = user_fixture()
      post_author = user_fixture()
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

      {:ok, post} =
        Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: post_author.id
        })

      %{
        goal: goal,
        post: post,
        goal_owner: goal_owner,
        post_author: post_author,
        other_user: other_user,
        group: group
      }
    end

    test "goal owner can create posts in their goal", %{goal: goal, goal_owner: goal_owner} do
      attrs = %{
        content: "New post by goal owner",
        post_type: :update,
        goal_id: goal.id,
        user_id: goal_owner.id
      }

      assert {:ok, post} = Goals.create_goal_post_with_ownership(attrs, goal_owner.id)
      assert post.content == "New post by goal owner"
      assert post.user_id == goal_owner.id
    end

    test "non-goal-owner cannot create posts in others' goals", %{
      goal: goal,
      other_user: other_user
    } do
      attrs = %{
        content: "Unauthorized post",
        post_type: :update,
        goal_id: goal.id,
        user_id: other_user.id
      }

      assert {:error, :unauthorized} = Goals.create_goal_post_with_ownership(attrs, other_user.id)
    end

    test "post author can update their own post", %{post: post, post_author: post_author} do
      assert {:ok, updated_post} =
               Goals.update_goal_post_with_ownership(
                 post,
                 %{content: "Updated content"},
                 post_author.id
               )

      assert updated_post.content == "Updated content"
    end

    test "non-post-author cannot update others' posts", %{post: post, other_user: other_user} do
      assert {:error, :unauthorized} =
               Goals.update_goal_post_with_ownership(
                 post,
                 %{content: "Unauthorized update"},
                 other_user.id
               )
    end

    test "goal owner cannot update others' posts in their goal", %{
      post: post,
      goal_owner: goal_owner
    } do
      # Even though the goal owner owns the goal, they shouldn't be able to edit posts by other users
      assert {:error, :unauthorized} =
               Goals.update_goal_post_with_ownership(
                 post,
                 %{content: "Goal owner trying to edit"},
                 goal_owner.id
               )
    end

    test "post author can delete their own post", %{post: post, post_author: post_author} do
      assert {:ok, _deleted_post} = Goals.delete_goal_post_with_ownership(post, post_author.id)
    end

    test "non-post-author cannot delete others' posts", %{post: post, other_user: other_user} do
      assert {:error, :unauthorized} = Goals.delete_goal_post_with_ownership(post, other_user.id)
    end

    test "goal owner cannot delete others' posts in their goal", %{
      post: post,
      goal_owner: goal_owner
    } do
      # Even though the goal owner owns the goal, they shouldn't be able to delete posts by other users
      assert {:error, :unauthorized} = Goals.delete_goal_post_with_ownership(post, goal_owner.id)
    end
  end

  describe "post creation workflow" do
    test "only goal owners can create posts" do
      goal_owner = user_fixture()
      non_owner = user_fixture()

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

      # Goal owner can create posts
      attrs_owner = %{
        content: "Post by goal owner",
        post_type: :update,
        goal_id: goal.id,
        user_id: goal_owner.id
      }

      assert {:ok, _post} = Goals.create_goal_post_with_ownership(attrs_owner, goal_owner.id)

      # Non-owner cannot create posts
      attrs_non_owner = %{
        content: "Post by non-owner",
        post_type: :update,
        goal_id: goal.id,
        user_id: non_owner.id
      }

      assert {:error, :unauthorized} =
               Goals.create_goal_post_with_ownership(attrs_non_owner, non_owner.id)
    end
  end

  describe "edge cases" do
    test "handles string vs atom goal_id in create_goal_post_with_ownership" do
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

      # Test with string goal_id
      attrs_string = %{
        "content" => "Test post",
        "post_type" => "update",
        "goal_id" => Integer.to_string(goal.id),
        "user_id" => Integer.to_string(goal_owner.id)
      }

      assert {:ok, _post} = Goals.create_goal_post_with_ownership(attrs_string, goal_owner.id)

      # Test with atom goal_id
      attrs_atom = %{
        content: "Test post 2",
        post_type: :update,
        goal_id: goal.id,
        user_id: goal_owner.id
      }

      assert {:ok, _post} = Goals.create_goal_post_with_ownership(attrs_atom, goal_owner.id)
    end
  end
end
