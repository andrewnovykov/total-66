defmodule HeadsUp.ReportsTest do
  use HeadsUp.DataCase, async: false

  alias HeadsUp.Reports
  alias HeadsUp.Repo
  alias HeadsUp.Goal
  alias HeadsUp.Goals.GoalPost
  import HeadsUp.GoalsFixtures
  import HeadsUp.AuthFixtures
  import HeadsUp.ChallengesFixtures

  describe "report_goal/3" do
    test "successfully creates a goal report" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:ok, report} =
               Reports.report_goal(goal.id, reporter.id, %{reason: "spam"})

      assert report.goal_id == goal.id
      assert report.user_id == reporter.id
      assert report.reason == "spam"
    end

    test "creates report with optional description" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:ok, report} =
               Reports.report_goal(goal.id, reporter.id, %{
                 reason: "offensive",
                 description: "Contains bad language"
               })

      assert report.description == "Contains bad language"
    end

    test "prevents duplicate reports from same user" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_goal(goal.id, reporter.id, %{reason: "spam"})
      assert {:error, :already_reported} = Reports.report_goal(goal.id, reporter.id, %{reason: "spam"})
    end

    test "prevents reporting own goal" do
      user = user_fixture()
      goal = goal_fixture(%{user_id: user.id})

      assert {:error, :cannot_report_own} =
               Reports.report_goal(goal.id, user.id, %{reason: "spam"})
    end

    test "returns not_found for nonexistent goal" do
      reporter = user_fixture()

      assert {:error, :not_found} =
               Reports.report_goal(999_999, reporter.id, %{reason: "spam"})
    end

    test "requires valid reason" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:error, changeset} =
               Reports.report_goal(goal.id, reporter.id, %{reason: "invalid_reason"})

      assert %Ecto.Changeset{} = changeset
    end

    test "requires reason to be present" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:error, changeset} =
               Reports.report_goal(goal.id, reporter.id, %{})

      assert %Ecto.Changeset{} = changeset
    end

    test "auto-hides goal after 3 reports" do
      goal = goal_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      assert {:ok, _} = Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      assert {:ok, _} = Reports.report_goal(goal.id, reporter2.id, %{reason: "offensive"})
      assert {:ok, _} = Reports.report_goal(goal.id, reporter3.id, %{reason: "inappropriate"})

      # Goal should now be hidden
      updated_goal = Repo.get!(Goal, goal.id)
      assert updated_goal.moderation_status == "hidden"
      assert updated_goal.report_count == 3
    end

    test "sets moderation_status to flagged before threshold" do
      goal = goal_fixture()
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_goal(goal.id, reporter.id, %{reason: "spam"})

      updated_goal = Repo.get!(Goal, goal.id)
      assert updated_goal.moderation_status == "flagged"
      assert updated_goal.report_count == 1
    end

    test "allows different users to report same goal" do
      goal = goal_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()

      assert {:ok, _} = Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      assert {:ok, _} = Reports.report_goal(goal.id, reporter2.id, %{reason: "offensive"})

      assert Reports.goal_report_count(goal.id) == 2
    end
  end

  describe "report_post/3" do
    test "successfully creates a post report" do
      post = goal_post_fixture()
      reporter = user_fixture()

      assert {:ok, report} =
               Reports.report_post(post.id, reporter.id, %{reason: "spam"})

      assert report.post_id == post.id
      assert report.user_id == reporter.id
      assert report.reason == "spam"
    end

    test "prevents duplicate reports from same user" do
      post = goal_post_fixture()
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_post(post.id, reporter.id, %{reason: "spam"})
      assert {:error, :already_reported} = Reports.report_post(post.id, reporter.id, %{reason: "spam"})
    end

    test "prevents reporting own post" do
      user = user_fixture()
      goal = goal_fixture(%{user_id: user.id})
      post = goal_post_fixture(%{user_id: user.id, goal_id: goal.id})

      assert {:error, :cannot_report_own} =
               Reports.report_post(post.id, user.id, %{reason: "spam"})
    end

    test "returns not_found for nonexistent post" do
      reporter = user_fixture()

      assert {:error, :not_found} =
               Reports.report_post(999_999, reporter.id, %{reason: "spam"})
    end

    test "auto-hides post after 3 reports" do
      post = goal_post_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      assert {:ok, _} = Reports.report_post(post.id, reporter1.id, %{reason: "spam"})
      assert {:ok, _} = Reports.report_post(post.id, reporter2.id, %{reason: "offensive"})
      assert {:ok, _} = Reports.report_post(post.id, reporter3.id, %{reason: "inappropriate"})

      updated_post = Repo.get!(GoalPost, post.id)
      assert updated_post.moderation_status == "hidden"
      assert updated_post.report_count == 3
    end
  end

  describe "has_reported_goal?/2" do
    test "returns true when user has reported the goal" do
      goal = goal_fixture()
      reporter = user_fixture()

      Reports.report_goal(goal.id, reporter.id, %{reason: "spam"})

      assert Reports.has_reported_goal?(goal.id, reporter.id) == true
    end

    test "returns false when user has not reported the goal" do
      goal = goal_fixture()
      user = user_fixture()

      assert Reports.has_reported_goal?(goal.id, user.id) == false
    end
  end

  describe "has_reported_post?/2" do
    test "returns true when user has reported the post" do
      post = goal_post_fixture()
      reporter = user_fixture()

      Reports.report_post(post.id, reporter.id, %{reason: "spam"})

      assert Reports.has_reported_post?(post.id, reporter.id) == true
    end

    test "returns false when user has not reported the post" do
      post = goal_post_fixture()
      user = user_fixture()

      assert Reports.has_reported_post?(post.id, user.id) == false
    end
  end

  describe "goal_report_count/1" do
    test "returns correct count" do
      goal = goal_fixture()

      assert Reports.goal_report_count(goal.id) == 0

      reporter1 = user_fixture()
      Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      assert Reports.goal_report_count(goal.id) == 1

      reporter2 = user_fixture()
      Reports.report_goal(goal.id, reporter2.id, %{reason: "spam"})
      assert Reports.goal_report_count(goal.id) == 2
    end
  end

  describe "goal_hidden?/1 and post_hidden?/1" do
    test "goal_hidden? returns false below threshold" do
      goal = goal_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()

      Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      Reports.report_goal(goal.id, reporter2.id, %{reason: "spam"})

      refute Reports.goal_hidden?(goal.id)
    end

    test "goal_hidden? returns true at threshold" do
      goal = goal_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      Reports.report_goal(goal.id, reporter2.id, %{reason: "spam"})
      Reports.report_goal(goal.id, reporter3.id, %{reason: "spam"})

      assert Reports.goal_hidden?(goal.id)
    end

    test "post_hidden? returns true at threshold" do
      post = goal_post_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      Reports.report_post(post.id, reporter1.id, %{reason: "spam"})
      Reports.report_post(post.id, reporter2.id, %{reason: "spam"})
      Reports.report_post(post.id, reporter3.id, %{reason: "spam"})

      assert Reports.post_hidden?(post.id)
    end
  end

  # ============================================================================
  # User Reporting
  # ============================================================================

  describe "report_user/3" do
    test "successfully creates a user report" do
      reported_user = user_fixture()
      reporter = user_fixture()

      assert {:ok, report} =
               Reports.report_user(reported_user.id, reporter.id, %{reason: "harassment"})

      assert report.reported_user_id == reported_user.id
      assert report.user_id == reporter.id
      assert report.reason == "harassment"
    end

    test "prevents duplicate reports from same user" do
      reported_user = user_fixture()
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_user(reported_user.id, reporter.id, %{reason: "spam"})

      assert {:error, :already_reported} =
               Reports.report_user(reported_user.id, reporter.id, %{reason: "spam"})
    end

    test "prevents reporting yourself" do
      user = user_fixture()

      assert {:error, :cannot_report_own} =
               Reports.report_user(user.id, user.id, %{reason: "spam"})
    end

    test "returns not_found for nonexistent user" do
      reporter = user_fixture()

      assert {:error, :not_found} =
               Reports.report_user(999_999, reporter.id, %{reason: "spam"})
    end

    test "auto-hides user after 3 reports" do
      reported_user = user_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      assert {:ok, _} = Reports.report_user(reported_user.id, reporter1.id, %{reason: "spam"})
      assert {:ok, _} = Reports.report_user(reported_user.id, reporter2.id, %{reason: "harassment"})
      assert {:ok, _} = Reports.report_user(reported_user.id, reporter3.id, %{reason: "offensive"})

      updated_user = Repo.get!(HeadsUp.Users, reported_user.id)
      assert updated_user.moderation_status == "hidden"
      assert updated_user.report_count == 3
    end

    test "sets moderation_status to flagged before threshold" do
      reported_user = user_fixture()
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_user(reported_user.id, reporter.id, %{reason: "spam"})

      updated_user = Repo.get!(HeadsUp.Users, reported_user.id)
      assert updated_user.moderation_status == "flagged"
      assert updated_user.report_count == 1
    end
  end

  describe "has_reported_user?/2" do
    test "returns true when user has been reported" do
      reported_user = user_fixture()
      reporter = user_fixture()

      Reports.report_user(reported_user.id, reporter.id, %{reason: "spam"})

      assert Reports.has_reported_user?(reported_user.id, reporter.id) == true
    end

    test "returns false when user has not been reported" do
      reported_user = user_fixture()
      user = user_fixture()

      assert Reports.has_reported_user?(reported_user.id, user.id) == false
    end
  end

  describe "user_report_count/1" do
    test "returns correct count" do
      reported_user = user_fixture()

      assert Reports.user_report_count(reported_user.id) == 0

      reporter1 = user_fixture()
      Reports.report_user(reported_user.id, reporter1.id, %{reason: "spam"})
      assert Reports.user_report_count(reported_user.id) == 1

      reporter2 = user_fixture()
      Reports.report_user(reported_user.id, reporter2.id, %{reason: "spam"})
      assert Reports.user_report_count(reported_user.id) == 2
    end
  end

  describe "user_hidden?/1" do
    test "returns false below threshold" do
      reported_user = user_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()

      Reports.report_user(reported_user.id, reporter1.id, %{reason: "spam"})
      Reports.report_user(reported_user.id, reporter2.id, %{reason: "spam"})

      refute Reports.user_hidden?(reported_user.id)
    end

    test "returns true at threshold" do
      reported_user = user_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      Reports.report_user(reported_user.id, reporter1.id, %{reason: "spam"})
      Reports.report_user(reported_user.id, reporter2.id, %{reason: "spam"})
      Reports.report_user(reported_user.id, reporter3.id, %{reason: "spam"})

      assert Reports.user_hidden?(reported_user.id)
    end
  end

  # ============================================================================
  # Challenge Reporting
  # ============================================================================

  describe "report_challenge/3" do
    test "successfully creates a challenge report" do
      challenge = challenge_fixture(%{is_template: true})
      reporter = user_fixture()

      assert {:ok, report} =
               Reports.report_challenge(challenge.id, reporter.id, %{reason: "spam"})

      assert report.challenge_id == challenge.id
      assert report.user_id == reporter.id
      assert report.reason == "spam"
    end

    test "prevents duplicate reports from same user" do
      challenge = challenge_fixture(%{is_template: true})
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_challenge(challenge.id, reporter.id, %{reason: "spam"})

      assert {:error, :already_reported} =
               Reports.report_challenge(challenge.id, reporter.id, %{reason: "spam"})
    end

    test "prevents reporting own challenge" do
      user = user_fixture()
      challenge = challenge_fixture(%{is_template: true, user: user})

      assert {:error, :cannot_report_own} =
               Reports.report_challenge(challenge.id, user.id, %{reason: "spam"})
    end

    test "returns not_found for nonexistent challenge" do
      reporter = user_fixture()

      assert {:error, :not_found} =
               Reports.report_challenge(999_999, reporter.id, %{reason: "spam"})
    end

    test "auto-hides challenge after 3 reports" do
      challenge = challenge_fixture(%{is_template: true})
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      assert {:ok, _} = Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      assert {:ok, _} = Reports.report_challenge(challenge.id, reporter2.id, %{reason: "offensive"})
      assert {:ok, _} = Reports.report_challenge(challenge.id, reporter3.id, %{reason: "inappropriate"})

      updated = Repo.get!(HeadsUp.Challenges.Challenge, challenge.id)
      assert updated.moderation_status == "hidden"
      assert updated.report_count == 3
    end

    test "sets moderation_status to flagged before threshold" do
      challenge = challenge_fixture(%{is_template: true})
      reporter = user_fixture()

      assert {:ok, _} = Reports.report_challenge(challenge.id, reporter.id, %{reason: "spam"})

      updated = Repo.get!(HeadsUp.Challenges.Challenge, challenge.id)
      assert updated.moderation_status == "flagged"
      assert updated.report_count == 1
    end
  end

  describe "has_reported_challenge?/2" do
    test "returns true when challenge has been reported" do
      challenge = challenge_fixture(%{is_template: true})
      reporter = user_fixture()

      Reports.report_challenge(challenge.id, reporter.id, %{reason: "spam"})

      assert Reports.has_reported_challenge?(challenge.id, reporter.id) == true
    end

    test "returns false when challenge has not been reported" do
      challenge = challenge_fixture(%{is_template: true})
      user = user_fixture()

      assert Reports.has_reported_challenge?(challenge.id, user.id) == false
    end
  end

  describe "challenge_report_count/1" do
    test "returns correct count" do
      challenge = challenge_fixture(%{is_template: true})

      assert Reports.challenge_report_count(challenge.id) == 0

      reporter1 = user_fixture()
      Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      assert Reports.challenge_report_count(challenge.id) == 1

      reporter2 = user_fixture()
      Reports.report_challenge(challenge.id, reporter2.id, %{reason: "spam"})
      assert Reports.challenge_report_count(challenge.id) == 2
    end
  end

  describe "challenge_hidden?/1" do
    test "returns false below threshold" do
      challenge = challenge_fixture(%{is_template: true})
      reporter1 = user_fixture()
      reporter2 = user_fixture()

      Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter2.id, %{reason: "spam"})

      refute Reports.challenge_hidden?(challenge.id)
    end

    test "returns true at threshold" do
      challenge = challenge_fixture(%{is_template: true})
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter2.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter3.id, %{reason: "spam"})

      assert Reports.challenge_hidden?(challenge.id)
    end
  end

  describe "hidden content filtering" do
    test "hidden goals are excluded from list_goals" do
      goal = goal_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      # Report until hidden
      Reports.report_goal(goal.id, reporter1.id, %{reason: "spam"})
      Reports.report_goal(goal.id, reporter2.id, %{reason: "spam"})
      Reports.report_goal(goal.id, reporter3.id, %{reason: "spam"})

      goals = HeadsUp.Goals.list_goals()
      refute Enum.any?(goals, &(&1.id == goal.id))
    end

    test "hidden posts are excluded from list_goal_posts" do
      goal = goal_fixture()
      post = goal_post_fixture(%{goal_id: goal.id})
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      # Report until hidden
      Reports.report_post(post.id, reporter1.id, %{reason: "spam"})
      Reports.report_post(post.id, reporter2.id, %{reason: "spam"})
      Reports.report_post(post.id, reporter3.id, %{reason: "spam"})

      posts = HeadsUp.Goals.list_goal_posts(goal.id)
      refute Enum.any?(posts, &(&1.id == post.id))
    end

    test "hidden users are excluded from list_users" do
      user = user_fixture()
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      # Report until hidden
      Reports.report_user(user.id, reporter1.id, %{reason: "spam"})
      Reports.report_user(user.id, reporter2.id, %{reason: "spam"})
      Reports.report_user(user.id, reporter3.id, %{reason: "spam"})

      users = HeadsUp.Accounts.list_users()
      refute Enum.any?(users, &(&1.id == user.id))
    end

    test "hidden challenges are excluded from list_public_challenges" do
      challenge = challenge_fixture(%{is_template: true})
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      # Report until hidden
      Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter2.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter3.id, %{reason: "spam"})

      challenges = HeadsUp.Challenges.list_public_challenges()
      refute Enum.any?(challenges, &(&1.id == challenge.id))
    end

    test "hidden challenges are excluded from list_templates" do
      challenge = challenge_fixture(%{is_template: true})
      reporter1 = user_fixture()
      reporter2 = user_fixture()
      reporter3 = user_fixture()

      # Report until hidden
      Reports.report_challenge(challenge.id, reporter1.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter2.id, %{reason: "spam"})
      Reports.report_challenge(challenge.id, reporter3.id, %{reason: "spam"})

      templates = HeadsUp.Challenges.list_templates()
      refute Enum.any?(templates, &(&1.id == challenge.id))
    end
  end
end
