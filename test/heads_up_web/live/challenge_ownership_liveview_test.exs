defmodule HeadsUpWeb.ChallengeOwnershipLiveViewTest do
  @moduledoc """
  Comprehensive LiveView-level ownership tests for challenges.
  Verifies that server-side event handlers reject actions from non-owners.
  """
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures
  import HeadsUp.ChallengesFixtures

  alias HeadsUp.Challenges

  describe "challenge edit page - non-owner blocked" do
    setup do
      owner = user_fixture()
      non_owner = user_fixture()
      challenge = challenge_fixture(%{user: owner})
      %{owner: owner, non_owner: non_owner, challenge: challenge}
    end

    test "non-owner is redirected from edit page", %{
      conn: conn,
      non_owner: non_owner,
      challenge: challenge
    } do
      conn = log_in_user(conn, non_owner)

      {:ok, _lv, html} =
        live(conn, ~p"/challenges/#{challenge.id}/edit")
        |> follow_redirect(conn)

      assert html =~ "You can only edit your own challenges"
    end

    test "owner can access edit page", %{conn: conn, owner: owner, challenge: challenge} do
      conn = log_in_user(conn, owner)
      {:ok, _lv, html} = live(conn, ~p"/challenges/#{challenge.id}/edit")

      assert html =~ "Edit Challenge"
    end
  end

  describe "challenge show page - non-owner cannot manage" do
    setup do
      owner = user_fixture()
      non_owner = user_fixture()
      challenge = challenge_fixture(%{user: owner, visibility: :public})
      %{owner: owner, non_owner: non_owner, challenge: challenge}
    end

    test "non-owner cannot delete challenge via event", %{
      conn: conn,
      non_owner: non_owner,
      challenge: challenge
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/challenges/#{challenge.id}")

      html = render_click(lv, "delete_challenge", %{})
      assert html =~ "don&#39;t have permission"

      # Challenge should still exist
      assert Challenges.get_challenge(challenge.id)
    end

    test "non-owner cannot share as template via event", %{
      conn: conn,
      non_owner: non_owner,
      challenge: challenge
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/challenges/#{challenge.id}")

      html = render_click(lv, "share_as_template", %{})
      assert html =~ "don&#39;t have permission"
    end

    test "non-owner cannot fail challenge via event", %{
      conn: conn,
      non_owner: non_owner,
      challenge: challenge
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/challenges/#{challenge.id}")

      # Set failure reason and try to confirm
      render_click(lv, "show_fail_modal", %{})
      render_click(lv, "update_failure_reason", %{"value" => "test reason"})
      html = render_click(lv, "confirm_fail_challenge", %{})

      assert html =~ "don&#39;t have permission" or html =~ "unauthorized" or
               html =~ "Could not fail"
    end

    test "non-owner cannot see management buttons", %{
      conn: conn,
      non_owner: non_owner,
      challenge: challenge
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/challenges/#{challenge.id}")

      refute has_element?(lv, "button", "Delete Challenge")
      refute has_element?(lv, "a", "Edit Challenge")
    end
  end

  describe "challenge context - ownership validation" do
    test "update_challenge prevents non-owner" do
      owner = user_fixture()
      non_owner = user_fixture()
      challenge = challenge_fixture(%{user: owner})

      assert {:error, :unauthorized} =
               Challenges.update_challenge(challenge, %{title: "Hacked"}, non_owner.id)
    end

    test "delete_challenge prevents non-owner" do
      owner = user_fixture()
      non_owner = user_fixture()
      challenge = challenge_fixture(%{user: owner})

      assert {:error, :unauthorized} =
               Challenges.delete_challenge(challenge, non_owner.id)
    end

    test "owner can update their challenge" do
      owner = user_fixture()
      challenge = challenge_fixture(%{user: owner})

      assert {:ok, updated} =
               Challenges.update_challenge(challenge, %{title: "New Title"}, owner.id)

      assert updated.title == "New Title"
    end

    test "owner can delete their challenge" do
      owner = user_fixture()
      challenge = challenge_fixture(%{user: owner})

      assert {:ok, _} = Challenges.delete_challenge(challenge, owner.id)
      assert is_nil(Challenges.get_challenge(challenge.id))
    end
  end
end
