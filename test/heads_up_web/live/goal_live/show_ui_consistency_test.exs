defmodule HeadsUpWeb.GoalLive.ShowUIConsistencyTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.{Goals, Groups}

  describe "UI consistency for goal ownership" do
    setup do
      goal_owner = user_fixture()
      visitor = user_fixture()

      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test description",
          big_description: "Detailed description",
          status: :active,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Test Step",
          goal_id: goal.id,
          order: 1
        })

      {:ok, post} =
        Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: goal_owner.id
        })

      %{
        goal_owner: goal_owner,
        visitor: visitor,
        goal: goal,
        step: step,
        post: post
      }
    end

    test "goal owner sees all edit controls", %{conn: conn, goal_owner: goal_owner, goal: goal} do
      conn = log_in_user(conn, goal_owner)
      {:ok, view, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Goal owner should see edit buttons for goal properties
      assert has_element?(view, "button[phx-click='edit_title']")
      assert has_element?(view, "button[phx-click='edit_description']")
      assert has_element?(view, "button[phx-click='edit_big_description']")
      assert has_element?(view, "button[phx-click='edit_goal_image']")

      # Goal owner should see step management controls
      assert has_element?(view, "form[phx-submit='add_step']")
      assert has_element?(view, "button[phx-click='toggle_step']")
      assert has_element?(view, "button[phx-click='edit_step']")
      assert has_element?(view, "button[phx-click='delete_step']")

      # Goal owner should see create post form
      assert has_element?(view, "form[phx-submit='create_post']")
      assert has_element?(view, "h3", "Share an Update")

      # Goal owner should see edit button for their own posts
      assert has_element?(view, "button[phx-click='edit_post']")

      # Goal owner should see delete button for their own posts
      assert has_element?(view, "button[phx-click='delete_post']")
    end

    test "visitor does not see edit controls", %{conn: conn, visitor: visitor, goal: goal} do
      conn = log_in_user(conn, visitor)
      {:ok, view, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Visitor should NOT see edit buttons for goal properties
      refute has_element?(view, "button[phx-click='edit_title']")
      refute has_element?(view, "button[phx-click='edit_description']")
      refute has_element?(view, "button[phx-click='edit_big_description']")
      refute has_element?(view, "button[phx-click='edit_goal_image']")

      # Visitor should NOT see step management controls
      refute has_element?(view, "form[phx-submit='add_step']")
      refute has_element?(view, "button[phx-click='toggle_step']")
      refute has_element?(view, "button[phx-click='edit_step']")
      refute has_element?(view, "button[phx-click='delete_step']")

      # Visitor should NOT see create post form
      refute has_element?(view, "form[phx-submit='create_post']")
      refute has_element?(view, "h3", "Share an Update")

      # Visitor should NOT see edit/delete buttons for posts
      refute has_element?(view, "button[phx-click='edit_post']")
      refute has_element?(view, "button[phx-click='delete_post']")
    end

    test "visitor sees read-only content correctly", %{conn: conn, visitor: visitor, goal: goal} do
      conn = log_in_user(conn, visitor)
      {:ok, _view, html} = live(conn, ~p"/goals/#{goal.id}")

      # Visitor should still see goal content
      assert html =~ goal.title
      assert html =~ goal.description
      assert html =~ goal.big_description

      # Visitor should see posts but without edit controls
      assert html =~ "Test post content"

      # Visitor should see steps but as read-only (non-interactive checkboxes)
      assert html =~ "Test Step"
    end

    test "guest user (not logged in) does not see edit controls", %{conn: conn, goal: goal} do
      # Don't log in any user
      {:ok, view, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Guest should NOT see any edit controls
      refute has_element?(view, "button[phx-click='edit_title']")
      refute has_element?(view, "button[phx-click='edit_description']")
      refute has_element?(view, "button[phx-click='edit_big_description']")
      refute has_element?(view, "form[phx-submit='add_step']")
      refute has_element?(view, "button[phx-click='toggle_step']")
      refute has_element?(view, "form[phx-submit='create_post']")
      refute has_element?(view, "button[phx-click='edit_post']")
      refute has_element?(view, "button[phx-click='delete_post']")
    end
  end

  describe "UI consistency for post ownership" do
    setup do
      goal_owner = user_fixture()
      post_author = user_fixture()
      other_user = user_fixture()

      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test description",
          status: :active,
          user_id: goal_owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Create posts by different users
      {:ok, goal_owner_post} =
        Goals.create_goal_post(%{
          content: "Post by goal owner",
          post_type: :update,
          goal_id: goal.id,
          user_id: goal_owner.id
        })

      {:ok, other_post} =
        Goals.create_goal_post(%{
          content: "Post by other user",
          post_type: :update,
          goal_id: goal.id,
          user_id: post_author.id
        })

      %{
        goal_owner: goal_owner,
        post_author: post_author,
        other_user: other_user,
        goal: goal,
        goal_owner_post: goal_owner_post,
        other_post: other_post
      }
    end

    test "goal owner sees edit/delete buttons only for their own posts", %{
      conn: conn,
      goal_owner: goal_owner,
      goal: goal
    } do
      conn = log_in_user(conn, goal_owner)
      {:ok, view, html} = live(conn, ~p"/goals/#{goal.id}")

      # Goal owner should see their own post with edit/delete buttons
      assert html =~ "Post by goal owner"

      # Goal owner should see other users' posts but without edit/delete buttons for those
      assert html =~ "Post by other user"

      # There should be at least one edit and delete button (for their own post)
      assert has_element?(view, "button[phx-click='edit_post']")
      assert has_element?(view, "button[phx-click='delete_post']")
    end

    test "post author sees edit/delete buttons only for their own posts", %{
      conn: conn,
      post_author: post_author,
      goal: goal
    } do
      conn = log_in_user(conn, post_author)
      {:ok, view, html} = live(conn, ~p"/goals/#{goal.id}")

      # Post author should see their own post with edit/delete buttons
      assert html =~ "Post by other user"

      # Post author should see goal owner's post but without edit/delete buttons for it
      assert html =~ "Post by goal owner"

      # There should be at least one edit and delete button (for their own post)
      assert has_element?(view, "button[phx-click='edit_post']")
      assert has_element?(view, "button[phx-click='delete_post']")
    end

    test "other user does not see edit/delete buttons for any posts", %{
      conn: conn,
      other_user: other_user,
      goal: goal
    } do
      conn = log_in_user(conn, other_user)
      {:ok, view, html} = live(conn, ~p"/goals/#{goal.id}")

      # Other user should see both posts but no edit/delete buttons
      assert html =~ "Post by goal owner"
      assert html =~ "Post by other user"

      # Should not see any edit/delete buttons
      refute has_element?(view, "button[phx-click='edit_post']")
      refute has_element?(view, "button[phx-click='delete_post']")
    end
  end
end
