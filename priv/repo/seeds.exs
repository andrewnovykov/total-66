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
  image_path: "/images/user-1.png"
}

case Auth.get_user_by_email(admin_attrs.email) do
  nil ->
    case Auth.register_user(admin_attrs) do
      {:ok, user} ->
        user
        |> Users.changeset(%{role: "admin"})
        |> Users.confirm_changeset()
        |> Repo.update!()

        IO.puts("Admin user created: #{user.email}")

      {:error, changeset} ->
        IO.puts("Failed to create admin user")
        IO.inspect(changeset)
    end

  _ ->
    IO.puts("Admin user already exists")
end

# Create sample users
Repo.insert!(%Users{
  user_name: "john_doe",
  name: "John Doe",
  bio: "Fitness enthusiast and challenge crusher",
  about: "Love setting and achieving ambitious challenges",
  level: 5,
  image_path: "/images/user-1.png"
})

Repo.insert!(%Users{
  user_name: "jane_smith",
  name: "Jane Smith",
  bio: "Career-focused professional",
  about: "Always striving for excellence in work and life",
  level: 8,
  image_path: "/images/user-2.png"
})

Repo.insert!(%Users{
  user_name: "mike_wilson",
  name: "Mike Wilson",
  bio: "Health and wellness advocate",
  about: "Passionate about living a balanced lifestyle",
  level: 3,
  image_path: "/images/user-3.png"
})

IO.puts("Seed data created successfully!")
IO.puts("Created #{Repo.aggregate(Users, :count)} users")
