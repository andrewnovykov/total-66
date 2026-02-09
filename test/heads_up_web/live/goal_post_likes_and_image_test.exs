defmodule HeadsUpWeb.GoalPostLikesAndImageTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.{Goals, Groups}

  describe "Goal post likes functionality" do
    setup :register_and_log_in_user

    test "user can like and unlike posts in goal feed", %{conn: conn, user: _user} do
      # Create another user who will create the post
      post_author = user_fixture(%{user_name: "postauthor", name: "Post Author"})

      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create a goal for the post author
      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal with posts",
          user_id: post_author.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Create a post by the post author (not the test user)
      {:ok, _post} =
        Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: post_author.id
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show the post with like button
      assert render(lv) =~ "Test post content"
      assert has_element?(lv, "button[phx-click='toggle_post_like']")

      # Click the like button
      lv
      |> element("button[phx-click='toggle_post_like']")
      |> render_click()

      # Should now show liked state (heart-solid icon appears when liked)
      assert has_element?(lv, "button[phx-click='toggle_post_like'] span.hero-heart-solid")

      # Click again to unlike
      lv
      |> element("button[phx-click='toggle_post_like']")
      |> render_click()

      # Should be back to unliked state (regular heart icon)
      assert has_element?(lv, "button[phx-click='toggle_post_like'] span.hero-heart")
      refute has_element?(lv, "button[phx-click='toggle_post_like'] span.hero-heart-solid")
    end

    test "guest users see like counts but cannot like posts", %{conn: _conn} do
      # Create user and setup goal with post
      user = user_fixture()

      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, _post} =
        Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: user.id
        })

      # Visit as guest
      conn = build_conn()
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show post content but no clickable like button
      assert render(lv) =~ "Test post content"
      refute has_element?(lv, "button[phx-click='toggle_post_like']")
    end

    test "like counts persist between page reloads", %{conn: conn, user: _user} do
      # Create another user who will create the post
      post_author = user_fixture(%{user_name: "postauthor3", name: "Post Author 3"})

      # Setup goal and post
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: post_author.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, _post} =
        Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: post_author.id
        })

      # Navigate and like the post
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      lv
      |> element("button[phx-click='toggle_post_like']")
      |> render_click()

      # Reload page
      {:ok, new_lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Like should still be there (red text = liked state)
      assert render(new_lv) =~ "text-red-500"
    end
  end

  describe "Goal image editing functionality" do
    setup :register_and_log_in_user

    test "goal owner can open image upload form", %{conn: conn, user: user} do
      # Create goal without image
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          image_path: nil,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show edit image button for owner
      assert has_element?(lv, "button[phx-click='edit_goal_image']")

      # Click edit image button
      lv
      |> element("button[phx-click='edit_goal_image']")
      |> render_click()

      # Should show file upload form
      assert has_element?(lv, "form[phx-submit='save_goal_image']")
      assert render(lv) =~ "Update Goal Image"
      assert render(lv) =~ "Click to upload"
      assert render(lv) =~ "PNG, JPG or JPEG"
    end

    test "goal owner can remove goal image", %{conn: conn, user: user} do
      # Create goal with image
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          image_path: "/uploads/existing.jpg",
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Click edit image button
      lv
      |> element("button[phx-click='edit_goal_image']")
      |> render_click()

      # Should show remove button since image exists
      assert has_element?(lv, "button[phx-click='remove_goal_image']")

      # Click remove button
      lv
      |> element("button[phx-click='remove_goal_image']")
      |> render_click()

      # Should show success message
      assert render(lv) =~ "Goal image removed"
    end

    test "non-owner cannot see image edit button", %{conn: conn, user: _user} do
      # Create another user who owns the goal
      other_user = user_fixture(%{user_name: "otheruser", name: "Other User"})

      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          # Different user owns this goal
          user_id: other_user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page as non-owner
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should NOT show edit image button
      refute has_element?(lv, "button[phx-click='edit_goal_image']")
    end

    test "upload form shows drag and drop area", %{conn: conn, user: user} do
      # Create goal
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate and open image editor
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      lv
      |> element("button[phx-click='edit_goal_image']")
      |> render_click()

      # Should show drag and drop area with file input
      html = render(lv)
      assert html =~ "Click to upload"
      assert html =~ "drag and drop"
      assert html =~ "Save Image"
    end

    test "can cancel image editing", %{conn: conn, user: user} do
      # Create goal
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate and open image editor
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      lv
      |> element("button[phx-click='edit_goal_image']")
      |> render_click()

      # Should show upload form
      assert has_element?(lv, "form[phx-submit='save_goal_image']")

      # Click cancel
      lv
      |> element("button[phx-click='cancel_edit_image']")
      |> render_click()

      # Should hide editing form
      refute has_element?(lv, "form[phx-submit='update_goal_image']")
      assert has_element?(lv, "button[phx-click='edit_goal_image']")
    end
  end

  describe "Self-interaction restrictions" do
    setup :register_and_log_in_user

    test "user cannot like their own posts", %{conn: conn, user: user} do
      # Create a goal and post by the user
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, post} =
        Goals.create_goal_post(%{
          content: "My own post",
          post_type: :update,
          goal_id: goal.id,
          user_id: user.id
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show post content but no like button for own post
      assert render(lv) =~ "My own post"
      # Owner sees edit/delete buttons instead of like button
      assert has_element?(lv, "button[phx-click='edit_post'][phx-value-post-id='#{post.id}']")

      refute has_element?(
               lv,
               "button[phx-click='toggle_post_like'][phx-value-post-id='#{post.id}']"
             )
    end

    test "user cannot like their own goal", %{conn: conn, user: user} do
      # Create a goal by the user
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "My Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show goal info but no interactive like button
      assert render(lv) =~ "My Goal"
      refute has_element?(lv, "button[phx-click='toggle_like']")

      # Should show like count in read-only format
      assert render(lv) =~ "Likes"
    end

    test "user cannot subscribe to their own goal", %{conn: conn, user: user} do
      # Create a goal by the user
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "My Goal",
          description: "Test goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show goal info but no interactive subscribe button
      assert render(lv) =~ "My Goal"
      refute has_element?(lv, "button[phx-click='toggle_subscribe']")

      # Should show subscriber count in read-only format
      assert render(lv) =~ "Subscribers"
    end

    test "other users can like and subscribe to goals normally", %{conn: conn, user: _user} do
      # Create another user who owns the goal
      goal_owner = user_fixture(%{user_name: "goalowner", name: "Goal Owner"})

      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Others Goal",
          description: "Test goal by someone else",
          user_id: goal_owner.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to goal page as different user
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show goal info with interactive buttons (non-owner sees like & subscribe)
      assert render(lv) =~ "Others Goal"
      assert has_element?(lv, "button[phx-click='toggle_like']")
      assert has_element?(lv, "button[phx-click='toggle_subscribe']")
    end
  end

  describe "Integration tests" do
    setup :register_and_log_in_user

    test "goal with posts, likes, and image editing works together", %{conn: conn, user: user} do
      # Create another user who will create the post
      post_author = user_fixture(%{user_name: "postauthor2", name: "Post Author 2"})

      # Create comprehensive goal setup
      {:ok, group} =
        Groups.create_group(%{
          name: "Integration Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Full Feature Goal",
          description: "Goal with all features",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 50,
          image_path: "/uploads/existing-goal.jpg",
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, _post} =
        Goals.create_goal_post(%{
          content: "Achievement unlocked!",
          post_type: :achievement,
          goal_id: goal.id,
          user_id: post_author.id
        })

      # Navigate to goal page
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should show goal image
      assert has_element?(lv, "img[src='/uploads/existing-goal.jpg']")

      # Should show post with like button
      assert render(lv) =~ "Achievement unlocked!"
      assert has_element?(lv, "button[phx-click='toggle_post_like']")

      # Should show image edit button (owner)
      assert has_element?(lv, "button[phx-click='edit_goal_image']")

      # Like the post
      lv
      |> element("button[phx-click='toggle_post_like']")
      |> render_click()

      # Should show liked state
      assert render(lv) =~ "text-red-500"

      # Open image upload form
      lv
      |> element("button[phx-click='edit_goal_image']")
      |> render_click()

      # Should show upload form
      assert has_element?(lv, "form[phx-submit='save_goal_image']")
      assert render(lv) =~ "Click to upload"

      # Like state should still be preserved
      assert render(lv) =~ "text-red-500"
    end
  end
end
