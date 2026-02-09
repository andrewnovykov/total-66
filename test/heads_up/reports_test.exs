defmodule HeadsUp.ReportsTest do
  use HeadsUp.DataCase, async: false

  alias HeadsUp.Reports
  alias HeadsUp.Repo
  import HeadsUp.AuthFixtures
  import HeadsUp.ChallengesFixtures

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
