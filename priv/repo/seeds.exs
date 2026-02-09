# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HeadsUp.Repo.insert!(%HeadsUp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias HeadsUp.Repo
alias HeadsUp.Users
alias HeadsUp.Group
alias HeadsUp.Goal
alias HeadsUp.GoalLike
alias HeadsUp.GoalSubscription
alias HeadsUp.Goals.GoalPost
alias HeadsUp.Auth

# Create admin user
admin_attrs = %{
  email: "admin@admin.com",
  password: "123456789012",
  role: "admin",
  user_name: "admin",
  name: "Admin User",
  bio: "System Administrator",
  about: "I am the admin.",
  level: 99,
  image_path: "/images/user-1.png",
  goal_amount: 0
}

case Auth.get_user_by_email(admin_attrs.email) do
  nil ->
    case Auth.register_user(admin_attrs) do
      {:ok, user} ->
        user
        |> Users.changeset(%{role: "admin"})
        |> Users.confirm_changeset()
        |> Repo.update!()

        IO.puts("✅ Admin user created: #{user.email}")

      {:error, changeset} ->
        IO.puts("❌ Failed to create admin user")
        IO.inspect(changeset)
    end

  _ ->
    IO.puts("ℹ️ Admin user already exists")
end

# Create sample users
user1 =
  Repo.insert!(%Users{
    user_name: "john_doe",
    name: "John Doe",
    bio: "Fitness enthusiast and goal crusher",
    about: "Love setting and achieving ambitious goals",
    level: 5,
    image_path: "/images/user-1.png",
    goal_amount: 12
  })

user2 =
  Repo.insert!(%Users{
    user_name: "jane_smith",
    name: "Jane Smith",
    bio: "Career-focused professional",
    about: "Always striving for excellence in work and life",
    level: 8,
    image_path: "/images/user-2.png",
    goal_amount: 8
  })

user3 =
  Repo.insert!(%Users{
    user_name: "mike_wilson",
    name: "Mike Wilson",
    bio: "Health and wellness advocate",
    about: "Passionate about living a balanced lifestyle",
    level: 3,
    image_path: "/images/user-3.png",
    goal_amount: 6
  })

# Create sample goal groups
fitness_group =
  Repo.insert!(%Group{
    name: "Fitness & Health",
    description: "Goals focused on physical health, exercise, nutrition and wellness",
    image_path: "/images/group-1.png",
    status: :published
  })

career_group =
  Repo.insert!(%Group{
    name: "Career Development",
    description: "Professional growth, skill building and career advancement goals",
    image_path: "/images/group-2.png",
    status: :published
  })

personal_group =
  Repo.insert!(%Group{
    name: "Personal Growth",
    description: "Self-improvement, learning and personal development goals",
    image_path: "/images/group-3.png",
    status: :published
  })

financial_group =
  Repo.insert!(%Group{
    name: "Financial Goals",
    description: "Saving, investing and financial planning objectives",
    image_path: "/images/group-4.png",
    status: :published
  })

# Create sample goals
Repo.insert!(%Goal{
  title: "Run a Marathon",
  description: "Complete a full 26.2 mile marathon race by the end of the year",
  status: :active,
  privacy: :public,
  target_date: ~U[2025-12-31 23:59:59Z],
  progress: 35,
  image_path: "/images/big-pic.jpg",
  group_id: fitness_group.id,
  user_id: user1.id
})

Repo.insert!(%Goal{
  title: "Lose 20 Pounds and Build Muscle Mass Through Consistent Training",
  description: "Achieve healthy weight loss through diet and exercise",
  status: :active,
  privacy: :public,
  target_date: ~U[2025-09-30 23:59:59Z],
  progress: 60,
  image_path: "/images/big-pic.jpg",
  group_id: fitness_group.id,
  user_id: user3.id
})

Repo.insert!(%Goal{
  title: "Learn Python Programming and Machine Learning Fundamentals for Career Advancement",
  description: "Master Python fundamentals and build 3 projects",
  status: :active,
  privacy: :public,
  target_date: ~U[2025-08-15 23:59:59Z],
  progress: 25,
  image_path: "/images/big-pic.jpg",
  group_id: career_group.id,
  user_id: user2.id
})

Repo.insert!(%Goal{
  title: "Get Promoted to Senior Developer",
  description: "Demonstrate leadership skills and technical expertise for promotion",
  status: :active,
  privacy: :private,
  target_date: ~U[2025-12-01 23:59:59Z],
  progress: 45,
  image_path: "/images/big-pic.jpg",
  group_id: career_group.id,
  user_id: user1.id
})

Repo.insert!(%Goal{
  title: "Read 24 Books This Year on Personal Development and Business Strategy",
  description: "Read 2 books per month to expand knowledge and perspective",
  status: :active,
  privacy: :public,
  target_date: ~U[2025-12-31 23:59:59Z],
  progress: 40,
  image_path: "/images/big-pic.jpg",
  group_id: personal_group.id,
  user_id: user2.id
})

Repo.insert!(%Goal{
  title: "Save $10,000 Emergency Fund for Financial Independence and Peace of Mind",
  description: "Build a robust emergency fund for financial security",
  status: :active,
  privacy: :public,
  target_date: ~U[2025-11-30 23:59:59Z],
  progress: 70,
  image_path: "/images/big-pic.jpg",
  group_id: financial_group.id,
  user_id: user3.id
})

Repo.insert!(%Goal{
  title: "Complete 30-Day Meditation Challenge for Mental Clarity and Stress Reduction",
  description: "Meditate for 30 days straight to build mindfulness habit",
  status: :completed,
  privacy: :public,
  target_date: ~U[2025-07-01 23:59:59Z],
  progress: 100,
  image_path: "/images/big-pic.jpg",
  group_id: personal_group.id,
  user_id: user1.id
})

# Add some sample likes and subscriptions
# Get goals from database to work with IDs
[goal1, goal2, goal3, goal4, goal5 | _] = Repo.all(Goal)

# Sample likes
Repo.insert!(%GoalLike{goal_id: goal1.id, user_id: user2.id})
Repo.insert!(%GoalLike{goal_id: goal1.id, user_id: user3.id})
Repo.insert!(%GoalLike{goal_id: goal2.id, user_id: user1.id})
Repo.insert!(%GoalLike{goal_id: goal3.id, user_id: user1.id})
Repo.insert!(%GoalLike{goal_id: goal3.id, user_id: user3.id})
Repo.insert!(%GoalLike{goal_id: goal4.id, user_id: user2.id})
Repo.insert!(%GoalLike{goal_id: goal5.id, user_id: user1.id})
Repo.insert!(%GoalLike{goal_id: goal5.id, user_id: user2.id})

# Sample subscriptions
Repo.insert!(%GoalSubscription{goal_id: goal1.id, user_id: user2.id})
Repo.insert!(%GoalSubscription{goal_id: goal1.id, user_id: user3.id})
Repo.insert!(%GoalSubscription{goal_id: goal2.id, user_id: user1.id})
Repo.insert!(%GoalSubscription{goal_id: goal3.id, user_id: user3.id})
Repo.insert!(%GoalSubscription{goal_id: goal4.id, user_id: user2.id})
Repo.insert!(%GoalSubscription{goal_id: goal5.id, user_id: user1.id})

# Sample goal posts for timeline/feed
Repo.insert!(%GoalPost{
  goal_id: goal1.id,
  user_id: user1.id,
  content:
    "Just started my marathon training today! Ran 3 miles and feeling great. The journey to 26.2 miles begins now!",
  post_type: :update,
  inserted_at: ~U[2025-07-01 08:00:00Z]
})

Repo.insert!(%GoalPost{
  goal_id: goal1.id,
  user_id: user1.id,
  content:
    "Completed my first 10k run! 🎉 This is a major milestone towards my marathon goal. The endurance is building up nicely.",
  post_type: :milestone,
  inserted_at: ~U[2025-07-02 18:30:00Z]
})

Repo.insert!(%GoalPost{
  goal_id: goal2.id,
  user_id: user3.id,
  content:
    "Week 4 of consistent training and meal prep. Lost 8 pounds so far! The discipline is paying off.",
  post_type: :update,
  inserted_at: ~U[2025-07-03 12:15:00Z]
})

Repo.insert!(%GoalPost{
  goal_id: goal2.id,
  user_id: user3.id,
  content:
    "Hit the halfway mark! 10 pounds down and feeling stronger than ever. The muscle definition is starting to show.",
  post_type: :achievement,
  inserted_at: ~U[2025-07-04 07:45:00Z]
})

Repo.insert!(%GoalPost{
  goal_id: goal3.id,
  user_id: user2.id,
  content:
    "Completed my first Python project - a simple task manager! The fundamentals are really clicking now.",
  post_type: :milestone,
  inserted_at: ~U[2025-07-04 20:00:00Z]
})

IO.puts("✅ Seed data created successfully!")
IO.puts("📊 Created #{Repo.aggregate(Users, :count)} users")
IO.puts("🎯 Created #{Repo.aggregate(Group, :count)} goal groups")
IO.puts("⭐ Created #{Repo.aggregate(Goal, :count)} goals")
IO.puts("❤️ Created #{Repo.aggregate(GoalLike, :count)} likes")
IO.puts("🔔 Created #{Repo.aggregate(GoalSubscription, :count)} subscriptions")
IO.puts("💬 Created #{Repo.aggregate(GoalPost, :count)} goal posts")
