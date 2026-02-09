# Script for populating the database with auth data.

alias HeadsUp.{Repo, Auth}

# Create superadmin user
superadmin_attrs = %{
  user_name: "superadmin",
  name: "Super Admin",
  bio: "System Administrator",
  about: "Main administrator of the HeadsUp platform",
  level: 100,
  image_path: "/images/defaults/admin.png",
  goal_amount: 0,
  email: "papapin777@gmail.com",
  password: "superadmin123",
  role: "admin"
}

case Auth.register_user(superadmin_attrs) do
  {:ok, user} ->
    IO.puts("✅ Created superadmin user: #{user.email}")
    
    # Confirm the user immediately
    case Auth.deliver_user_confirmation_instructions(user, &"http://localhost:4000/users/confirm/#{&1}") do
      {:ok, _} ->
        IO.puts("✅ Confirmation email would be sent (in development)")
      {:error, :already_confirmed} ->
        IO.puts("✅ User already confirmed")
      {:error, reason} ->
        IO.puts("❌ Failed to send confirmation: #{inspect(reason)}")
    end

  {:error, changeset} ->
    IO.puts("❌ Failed to create superadmin user:")
    IO.inspect(changeset.errors)
end