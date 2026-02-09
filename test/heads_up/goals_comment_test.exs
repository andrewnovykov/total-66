defmodule HeadsUp.GoalsCommentTest do
  use HeadsUp.DataCase

  alias HeadsUp.Goals
  alias HeadsUp.Goals.GoalComment

  import HeadsUp.AuthFixtures
  import HeadsUp.GoalsFixtures

  describe "Goal Comments" do
    setup do
      user = user_fixture()
      goal = goal_fixture(%{user_id: user.id})

      {:ok, post} =
        Goals.create_goal_post(%{
          goal_id: goal.id,
          user_id: user.id,
          content: "Test post",
          post_type: :update
        })

      %{user: user, goal: goal, post: post}
    end

    test "list_comments/1 returns empty list when no comments", %{post: post} do
      assert Goals.list_comments(post.id) == []
    end

    test "list_comments/1 returns comments for a post", %{post: post, user: user} do
      {:ok, comment} =
        Goals.create_comment(%{
          goal_post_id: post.id,
          user_id: user.id,
          content: "Test comment"
        })

      comments = Goals.list_comments(post.id)
      assert length(comments) == 1
      assert hd(comments).id == comment.id
      assert hd(comments).content == "Test comment"
    end

    test "list_comments/1 preloads user", %{post: post, user: user} do
      {:ok, _comment} =
        Goals.create_comment(%{
          goal_post_id: post.id,
          user_id: user.id,
          content: "Test comment"
        })

      [comment] = Goals.list_comments(post.id)
      assert comment.user.id == user.id
    end

    test "list_comments/1 returns comments in chronological order", %{post: post, user: user} do
      {:ok, _c1} =
        Goals.create_comment(%{goal_post_id: post.id, user_id: user.id, content: "First"})

      {:ok, _c2} =
        Goals.create_comment(%{goal_post_id: post.id, user_id: user.id, content: "Second"})

      {:ok, _c3} =
        Goals.create_comment(%{goal_post_id: post.id, user_id: user.id, content: "Third"})

      comments = Goals.list_comments(post.id)
      contents = Enum.map(comments, & &1.content)
      assert contents == ["First", "Second", "Third"]
    end

    test "get_comment!/1 returns the comment", %{post: post, user: user} do
      {:ok, comment} =
        Goals.create_comment(%{
          goal_post_id: post.id,
          user_id: user.id,
          content: "Test"
        })

      fetched = Goals.get_comment!(comment.id)
      assert fetched.id == comment.id
      assert fetched.content == "Test"
    end

    test "get_comment!/1 raises for invalid id" do
      assert_raise Ecto.NoResultsError, fn ->
        Goals.get_comment!(0)
      end
    end

    test "create_comment/1 creates a comment", %{post: post, user: user} do
      assert {:ok, comment} =
               Goals.create_comment(%{
                 goal_post_id: post.id,
                 user_id: user.id,
                 content: "New comment"
               })

      assert comment.content == "New comment"
      assert comment.goal_post_id == post.id
      assert comment.user_id == user.id
    end

    test "create_comment/1 returns error for empty content", %{post: post, user: user} do
      assert {:error, changeset} =
               Goals.create_comment(%{
                 goal_post_id: post.id,
                 user_id: user.id,
                 content: ""
               })

      assert "can't be blank" in errors_on(changeset).content
    end

    test "create_comment/1 validates content length", %{post: post, user: user} do
      long_content = String.duplicate("a", 2001)

      assert {:error, changeset} =
               Goals.create_comment(%{
                 goal_post_id: post.id,
                 user_id: user.id,
                 content: long_content
               })

      assert "should be at most 2000 character(s)" in errors_on(changeset).content
    end

    test "delete_comment/2 deletes own comment", %{post: post, user: user} do
      {:ok, comment} =
        Goals.create_comment(%{
          goal_post_id: post.id,
          user_id: user.id,
          content: "To delete"
        })

      assert {:ok, _} = Goals.delete_comment(comment, user.id)
      assert Goals.list_comments(post.id) == []
    end

    test "delete_comment/2 returns error for other user's comment", %{post: post, user: user} do
      other_user = user_fixture()

      {:ok, comment} =
        Goals.create_comment(%{
          goal_post_id: post.id,
          user_id: user.id,
          content: "Owner's comment"
        })

      assert {:error, :unauthorized} = Goals.delete_comment(comment, other_user.id)
      # Comment should still exist
      assert length(Goals.list_comments(post.id)) == 1
    end

    test "count_comments/1 returns correct count", %{post: post, user: user} do
      assert Goals.count_comments(post.id) == 0

      {:ok, _} = Goals.create_comment(%{goal_post_id: post.id, user_id: user.id, content: "One"})
      assert Goals.count_comments(post.id) == 1

      {:ok, _} = Goals.create_comment(%{goal_post_id: post.id, user_id: user.id, content: "Two"})
      assert Goals.count_comments(post.id) == 2
    end

    test "comment_counts_by_post_ids/1 returns counts map", %{goal: goal, user: user} do
      # Create another post
      {:ok, post1} =
        Goals.create_goal_post(%{
          goal_id: goal.id,
          user_id: user.id,
          content: "Post 1",
          post_type: :update
        })

      {:ok, post2} =
        Goals.create_goal_post(%{
          goal_id: goal.id,
          user_id: user.id,
          content: "Post 2",
          post_type: :update
        })

      # Add comments
      {:ok, _} = Goals.create_comment(%{goal_post_id: post1.id, user_id: user.id, content: "C1"})
      {:ok, _} = Goals.create_comment(%{goal_post_id: post1.id, user_id: user.id, content: "C2"})
      {:ok, _} = Goals.create_comment(%{goal_post_id: post2.id, user_id: user.id, content: "C3"})

      counts = Goals.comment_counts_by_post_ids([post1.id, post2.id])

      assert counts[post1.id] == 2
      assert counts[post2.id] == 1
    end

    test "comment_counts_by_post_ids/1 returns empty map for empty list" do
      assert Goals.comment_counts_by_post_ids([]) == %{}
    end
  end
end
