defmodule HeadsUp.ChallengesTest do
  use HeadsUp.DataCase

  alias HeadsUp.Challenges
  alias HeadsUp.ChallengesFixtures
  alias HeadsUp.AuthFixtures

  describe "challenges" do
    setup do
      user = AuthFixtures.user_fixture()
      admin = AuthFixtures.admin_fixture()
      category = ChallengesFixtures.challenge_category_fixture()
      %{user: user, admin: admin, category: category}
    end

    test "list_public_challenges/0 returns only public active templates", %{admin: admin} do
      public_template =
        ChallengesFixtures.predefined_challenge_fixture(%{user: admin, visibility: :public})

      _private_template =
        ChallengesFixtures.predefined_challenge_fixture(%{user: admin, visibility: :private})

      challenges = Challenges.list_public_challenges()
      assert length(challenges) == 1
      assert hd(challenges).id == public_template.id
    end

    test "list_visible_challenges/1 includes user's own templates", %{user: user} do
      private =
        ChallengesFixtures.challenge_fixture(%{
          user: user,
          visibility: :private,
          is_template: true
        })

      challenges = Challenges.list_visible_challenges(user.id)
      assert Enum.any?(challenges, &(&1.id == private.id))
    end

    test "get_challenge!/1 returns the challenge with preloads", %{user: user} do
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})
      fetched = Challenges.get_challenge!(challenge.id)

      assert fetched.id == challenge.id
      assert fetched.creator != nil
    end

    test "create_challenge/2 creates a custom challenge for users", %{
      user: user,
      category: category
    } do
      attrs = %{
        title: "My Custom Challenge",
        description: "Test",
        visibility: :public,
        category_id: category.id,
        start_date: Date.utc_today(),
        end_date: Date.add(Date.utc_today(), 30)
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, user)
      assert challenge.title == "My Custom Challenge"
      assert challenge.type == :custom
      assert challenge.creator_user_id == user.id
    end

    test "create_challenge/2 allows admin to create predefined challenges", %{
      admin: admin,
      category: category
    } do
      attrs = %{
        title: "Official Challenge",
        description: "Test",
        type: :predefined,
        category_id: category.id,
        duration_days: 30
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, admin)
      assert challenge.type == :predefined
      assert challenge.duration_days == 30
    end

    test "create_challenge/2 prevents non-admin from creating predefined challenges", %{
      user: user,
      category: category
    } do
      attrs = %{
        title: "Fake Official",
        description: "Test",
        type: :predefined,
        category_id: category.id,
        duration_days: 30
      }

      assert {:error, :unauthorized, _} = Challenges.create_challenge(attrs, user)
    end

    test "create_challenge/2 requires category_id, start_date, end_date", %{user: user} do
      attrs = %{title: "Missing Fields", description: "Test"}

      assert {:error, changeset} = Challenges.create_challenge(attrs, user)
      assert "is required" in errors_on(changeset).category_id
      assert "is required" in errors_on(changeset).start_date
      assert "is required" in errors_on(changeset).end_date
    end

    test "create_challenge/2 accepts consistently string-keyed attrs", %{
      user: user,
      category: category
    } do
      attrs = %{
        "title" => "String Params Challenge",
        "description" => "Created from string-keyed params",
        "visibility" => "public",
        "category_id" => category.id,
        "start_date" => Date.utc_today(),
        "end_date" => Date.add(Date.utc_today(), 30)
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, user)
      assert challenge.title == "String Params Challenge"
      assert challenge.creator_user_id == user.id
    end

    test "create_challenge/2 rejects mixed atom/string keyed attrs", %{
      user: user,
      category: category
    } do
      attrs = %{
        :title => "Mixed Keys",
        "description" => "This should be rejected",
        :visibility => :public,
        :category_id => category.id,
        :start_date => Date.utc_today(),
        :end_date => Date.add(Date.utc_today(), 30)
      }

      assert {:error, :invalid_attrs, _} = Challenges.create_challenge(attrs, user)
    end

    test "update_challenge/3 allows owner to update", %{user: user} do
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})

      assert {:ok, updated} =
               Challenges.update_challenge(challenge, %{title: "Updated Title"}, user.id)

      assert updated.title == "Updated Title"
    end

    test "update_challenge/3 prevents non-owner from updating", %{user: user} do
      other_user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})

      assert {:error, :unauthorized} =
               Challenges.update_challenge(challenge, %{title: "Hacked"}, other_user.id)
    end

    test "delete_challenge/2 allows owner to delete", %{user: user} do
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})

      assert {:ok, _} = Challenges.delete_challenge(challenge, user.id)
      assert is_nil(Challenges.get_challenge(challenge.id))
    end

    test "delete_challenge/2 prevents non-owner from deleting", %{user: user} do
      other_user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})

      assert {:error, :unauthorized} = Challenges.delete_challenge(challenge, other_user.id)
    end
  end

  describe "challenge participation" do
    setup do
      creator = AuthFixtures.user_fixture()
      participant = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: creator})
      %{creator: creator, participant: participant, challenge: challenge}
    end

    test "join_challenge/2 allows user to join public challenge", %{
      participant: participant,
      challenge: challenge
    } do
      assert {:ok, p} = Challenges.join_challenge(challenge.id, participant.id)
      assert p.status == :active
      assert p.challenge_id == challenge.id
      assert p.user_id == participant.id
    end

    test "join_challenge/2 prevents duplicate joining", %{
      participant: participant,
      challenge: challenge
    } do
      {:ok, _} = Challenges.join_challenge(challenge.id, participant.id)
      assert {:error, :already_joined} = Challenges.join_challenge(challenge.id, participant.id)
    end

    test "join_challenge/2 respects visibility for private challenges", %{creator: creator} do
      other_user = AuthFixtures.user_fixture()
      private = ChallengesFixtures.challenge_fixture(%{user: creator, visibility: :private})

      assert {:error, :access_denied} = Challenges.join_challenge(private.id, other_user.id)
    end

    test "leave_challenge/2 allows participant to leave", %{
      participant: participant,
      challenge: challenge
    } do
      {:ok, _} = Challenges.join_challenge(challenge.id, participant.id)
      assert {:ok, p} = Challenges.leave_challenge(challenge.id, participant.id)
      assert p.status == :dropped
    end

    test "get_participant/2 returns participant record", %{
      participant: participant,
      challenge: challenge
    } do
      {:ok, _} = Challenges.join_challenge(challenge.id, participant.id)
      p = Challenges.get_participant(challenge.id, participant.id)
      assert p != nil
      assert p.user_id == participant.id
    end

    test "get_participant_count/1 returns correct count", %{
      participant: participant,
      challenge: challenge
    } do
      assert Challenges.get_participant_count(challenge.id) == 0

      {:ok, _} = Challenges.join_challenge(challenge.id, participant.id)
      assert Challenges.get_participant_count(challenge.id) == 1
    end
  end

  describe "phases and steps" do
    setup do
      user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user, type: :predefined})
      %{user: user, challenge: challenge}
    end

    test "create_phase/2 allows owner to create phase", %{user: user, challenge: challenge} do
      attrs = %{title: "Phase 1", order_index: 0, challenge_id: challenge.id}

      assert {:ok, phase} = Challenges.create_phase(attrs, user.id)
      assert phase.title == "Phase 1"
      assert phase.challenge_id == challenge.id
    end

    test "create_phase/2 prevents non-owner from creating phase", %{challenge: challenge} do
      other_user = AuthFixtures.user_fixture()
      attrs = %{title: "Phase 1", order_index: 0, challenge_id: challenge.id}

      assert {:error, :unauthorized} = Challenges.create_phase(attrs, other_user.id)
    end

    test "create_step/2 allows owner to create step", %{user: user, challenge: challenge} do
      phase = ChallengesFixtures.challenge_phase_fixture(%{challenge: challenge})
      attrs = %{title: "Step 1", order_index: 0, phase_id: phase.id}

      assert {:ok, step} = Challenges.create_step(attrs, user.id)
      assert step.title == "Step 1"
    end
  end

  describe "tasks" do
    setup do
      user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user, type: :custom})
      %{user: user, challenge: challenge}
    end

    test "create_task/2 allows owner to create task", %{user: user, challenge: challenge} do
      attrs = %{title: "Daily Task", schedule_type: :daily, challenge_id: challenge.id}

      assert {:ok, task} = Challenges.create_task(attrs, user.id)
      assert task.title == "Daily Task"
      assert task.schedule_type == :daily
    end

    test "create_task/2 prevents non-owner from creating task", %{challenge: challenge} do
      other_user = AuthFixtures.user_fixture()
      attrs = %{title: "Task", schedule_type: :daily, challenge_id: challenge.id}

      assert {:error, :unauthorized} = Challenges.create_task(attrs, other_user.id)
    end
  end

  describe "progress tracking" do
    setup do
      creator = AuthFixtures.user_fixture()
      participant_user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: creator, type: :predefined})
      phase = ChallengesFixtures.challenge_phase_fixture(%{challenge: challenge})
      step = ChallengesFixtures.challenge_step_fixture(%{phase: phase})

      {:ok, participant} = Challenges.join_challenge(challenge.id, participant_user.id)

      %{
        creator: creator,
        participant_user: participant_user,
        challenge: challenge,
        phase: phase,
        step: step,
        participant: participant
      }
    end

    test "complete_step/2 marks step as completed", %{participant: participant, step: step} do
      assert {:ok, progress} = Challenges.complete_step(participant.id, step.id)
      assert progress.completed_at != nil
    end

    test "step_completed?/2 returns correct status", %{participant: participant, step: step} do
      refute Challenges.step_completed?(participant.id, step.id)

      {:ok, _} = Challenges.complete_step(participant.id, step.id)
      assert Challenges.step_completed?(participant.id, step.id)
    end

    test "uncomplete_step/2 removes progress", %{participant: participant, step: step} do
      {:ok, _} = Challenges.complete_step(participant.id, step.id)
      assert Challenges.step_completed?(participant.id, step.id)

      {:ok, _} = Challenges.uncomplete_step(participant.id, step.id)
      refute Challenges.step_completed?(participant.id, step.id)
    end

    test "get_participant_progress/1 returns correct stats", %{
      participant: participant,
      step: _step,
      phase: _phase
    } do
      progress = Challenges.get_participant_progress(participant.id)
      assert progress.type == :predefined
      # New progress format uses days-based tracking
      assert progress.total_days > 0
      assert progress.days_elapsed >= 0
      assert progress.days_percentage >= 0.0
      assert progress.today_completed >= 0
      assert progress.today_failed >= 0
    end
  end

  describe "task completion" do
    setup do
      creator = AuthFixtures.user_fixture()
      participant_user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: creator, type: :custom})
      task = ChallengesFixtures.challenge_task_fixture(%{challenge: challenge})

      {:ok, participant} = Challenges.join_challenge(challenge.id, participant_user.id)

      %{
        challenge: challenge,
        task: task,
        participant: participant
      }
    end

    test "complete_task/3 marks task as completed for date", %{
      participant: participant,
      task: task
    } do
      assert {:ok, completion} = Challenges.complete_task(participant.id, task.id)
      assert completion.completed_date == Date.utc_today()
    end

    test "task_completed?/3 returns correct status", %{participant: participant, task: task} do
      refute Challenges.task_completed?(participant.id, task.id, Date.utc_today())

      {:ok, _} = Challenges.complete_task(participant.id, task.id)
      assert Challenges.task_completed?(participant.id, task.id, Date.utc_today())
    end

    test "uncomplete_task/3 removes completion", %{participant: participant, task: task} do
      {:ok, _} = Challenges.complete_task(participant.id, task.id)
      assert Challenges.task_completed?(participant.id, task.id, Date.utc_today())

      {:ok, _} = Challenges.uncomplete_task(participant.id, task.id, Date.utc_today())
      refute Challenges.task_completed?(participant.id, task.id, Date.utc_today())
    end
  end

  describe "fail challenge" do
    setup do
      owner = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: owner})
      {:ok, participant} = Challenges.join_challenge(challenge.id, owner.id)
      %{owner: owner, challenge: challenge, participant: participant}
    end

    test "owner can fail their challenge", %{owner: owner, challenge: challenge} do
      assert {:ok, failed} = Challenges.fail_challenge(challenge.id, owner.id, "Too hard")
      assert failed.status == :failed
      assert failed.failure_reason == "Too hard"
      assert failed.failed_at != nil
    end

    test "owner can fail without reason", %{owner: owner, challenge: challenge} do
      assert {:ok, failed} = Challenges.fail_challenge(challenge.id, owner.id)
      assert failed.status == :failed
      assert is_nil(failed.failure_reason)
    end

    test "fail also updates participant status", %{owner: owner, challenge: challenge} do
      {:ok, _} = Challenges.fail_challenge(challenge.id, owner.id, "Giving up")
      participant = Challenges.get_participant(challenge.id, owner.id)
      assert participant.status == :failed
      assert participant.failure_reason == "Giving up"
    end

    test "non-owner cannot fail challenge", %{challenge: challenge} do
      other_user = AuthFixtures.user_fixture()
      assert {:error, :unauthorized} = Challenges.fail_challenge(challenge.id, other_user.id)
    end

    test "cannot fail a template", %{owner: _owner} do
      admin = AuthFixtures.admin_fixture()
      template = ChallengesFixtures.predefined_challenge_fixture(%{user: admin})
      assert {:error, :cannot_fail_template} = Challenges.fail_challenge(template.id, admin.id)
    end

    test "cannot fail already-failed challenge", %{owner: owner, challenge: challenge} do
      {:ok, _} = Challenges.fail_challenge(challenge.id, owner.id)
      assert {:error, :already_failed} = Challenges.fail_challenge(challenge.id, owner.id)
    end
  end

  describe "daily check-ins" do
    setup do
      owner = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: owner})
      _task = ChallengesFixtures.challenge_task_fixture(%{challenge: challenge})
      {:ok, participant} = Challenges.join_challenge(challenge.id, owner.id)
      %{owner: owner, challenge: challenge, participant: participant}
    end

    test "create_daily_check_in/2 creates a check-in", %{
      participant: participant,
      challenge: challenge
    } do
      assert {:ok, check_in} =
               Challenges.create_daily_check_in(participant.id, %{note: "Great day!"})

      assert check_in.day_number == 1
      assert check_in.completed_date == Date.utc_today()
      assert check_in.challenge_id == challenge.id
      assert check_in.note == "Great day!"
    end

    test "create_daily_check_in/2 calculates task counts", %{participant: participant} do
      assert {:ok, check_in} = Challenges.create_daily_check_in(participant.id)
      # 1 daily task, none completed = 1 skipped
      assert check_in.total_tasks >= 0

      assert check_in.completed_tasks + check_in.failed_tasks + check_in.skipped_tasks ==
               check_in.total_tasks
    end

    test "cannot check in twice on same day", %{participant: participant} do
      {:ok, _} = Challenges.create_daily_check_in(participant.id)
      assert {:error, :already_checked_in} = Challenges.create_daily_check_in(participant.id)
    end

    test "has_checked_in_today?/1 returns correct status", %{participant: participant} do
      refute Challenges.has_checked_in_today?(participant.id)
      {:ok, _} = Challenges.create_daily_check_in(participant.id)
      assert Challenges.has_checked_in_today?(participant.id)
    end

    test "cannot check in on failed challenge", %{
      owner: owner,
      challenge: challenge,
      participant: participant
    } do
      {:ok, _} = Challenges.fail_challenge(challenge.id, owner.id)
      assert {:error, :challenge_not_active} = Challenges.create_daily_check_in(participant.id)
    end
  end

  describe "today tasks" do
    test "get_today_tasks/1 returns daily tasks" do
      owner = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: owner})

      task =
        ChallengesFixtures.challenge_task_fixture(%{challenge: challenge, schedule_type: :daily})

      tasks = Challenges.get_today_tasks(challenge.id)
      assert length(tasks) >= 1
      assert Enum.any?(tasks, &(&1.id == task.id))
    end
  end

  describe "challenge feed" do
    setup do
      owner = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: owner})
      _task = ChallengesFixtures.challenge_task_fixture(%{challenge: challenge})
      {:ok, participant} = Challenges.join_challenge(challenge.id, owner.id)
      %{owner: owner, challenge: challenge, participant: participant}
    end

    test "get_challenge_feed/1 returns check-ins", %{
      participant: participant,
      challenge: challenge
    } do
      {:ok, _} = Challenges.create_daily_check_in(participant.id, %{note: "Day 1 done"})

      feed = Challenges.get_challenge_feed(challenge.id)
      assert length(feed) == 1
      assert hd(feed).note == "Day 1 done"
    end

    test "get_challenge_feed/1 returns empty for no check-ins", %{challenge: challenge} do
      assert Challenges.get_challenge_feed(challenge.id) == []
    end

    test "get_daily_check_in!/1 returns check-in with preloads", %{participant: participant} do
      {:ok, check_in} = Challenges.create_daily_check_in(participant.id)
      fetched = Challenges.get_daily_check_in!(check_in.id)
      assert fetched.user != nil
      assert fetched.challenge != nil
    end
  end

  describe "unlimited challenge participation" do
    test "users can join unlimited challenges" do
      user = AuthFixtures.user_fixture()
      creator = AuthFixtures.user_fixture()

      # Create multiple challenges
      challenge1 = ChallengesFixtures.challenge_fixture(%{user: creator})
      challenge2 = ChallengesFixtures.challenge_fixture(%{user: creator})
      challenge3 = ChallengesFixtures.challenge_fixture(%{user: creator})
      challenge4 = ChallengesFixtures.challenge_fixture(%{user: creator})

      # User should be able to join all of them
      assert {:ok, _} = Challenges.join_challenge(challenge1.id, user.id)
      assert {:ok, _} = Challenges.join_challenge(challenge2.id, user.id)
      assert {:ok, _} = Challenges.join_challenge(challenge3.id, user.id)
      assert {:ok, _} = Challenges.join_challenge(challenge4.id, user.id)

      # Verify user is in all challenges
      assert Challenges.count_active_challenges(user.id) == 4
    end
  end

  describe "BUG-1 regression: user-created challenges are personal, not templates" do
    setup do
      user = AuthFixtures.user_fixture()
      admin = AuthFixtures.admin_fixture()
      category = ChallengesFixtures.challenge_category_fixture()
      %{user: user, admin: admin, category: category}
    end

    test "custom challenge created by user has is_template=false", %{
      user: user,
      category: category
    } do
      attrs = %{
        title: "My Personal Challenge",
        description: "A personal challenge",
        visibility: :public,
        category_id: category.id,
        start_date: Date.utc_today(),
        end_date: Date.add(Date.utc_today(), 30)
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, user)
      assert challenge.is_template == false
      assert challenge.type == :custom
    end

    test "custom challenge explicitly overrides is_template if passed as true", %{
      user: user,
      category: category
    } do
      attrs = %{
        title: "Sneaky Template Attempt",
        description: "Trying to create a template",
        visibility: :public,
        category_id: category.id,
        start_date: Date.utc_today(),
        end_date: Date.add(Date.utc_today(), 30),
        is_template: true
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, user)
      # Even if is_template is passed as true, non-admin custom should be forced to false
      assert challenge.is_template == false
    end

    test "predefined challenge created by admin has is_template=true", %{
      admin: admin,
      category: category
    } do
      attrs = %{
        title: "Official Template",
        description: "Admin template",
        type: :predefined,
        category_id: category.id,
        duration_days: 30
      }

      assert {:ok, challenge} = Challenges.create_challenge(attrs, admin)
      assert challenge.is_template == true
      assert challenge.type == :predefined
    end
  end
end
