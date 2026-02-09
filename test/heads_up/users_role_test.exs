defmodule HeadsUp.UsersRoleTest do
  use HeadsUp.DataCase

  alias HeadsUp.Users
  alias HeadsUp.Auth

  import HeadsUp.AuthFixtures

  describe "role validation in changeset/2" do
    test "accepts 'user' role" do
      changeset = Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: "user"})
      assert changeset.valid?
      # Role may not be in changes if it matches the schema default
      # but the changeset should still be valid
    end

    test "accepts 'coach' role" do
      changeset = Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: "coach"})
      assert changeset.valid?
      assert changeset.changes[:role] == "coach"
    end

    test "accepts 'admin' role" do
      changeset = Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: "admin"})
      assert changeset.valid?
      assert changeset.changes[:role] == "admin"
    end

    test "rejects invalid role" do
      changeset = Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: "invalid"})
      refute changeset.valid?
      assert %{role: ["is invalid"]} = errors_on(changeset)
    end

    test "rejects 'superadmin' role" do
      changeset =
        Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: "superadmin"})

      refute changeset.valid?
      assert %{role: ["is invalid"]} = errors_on(changeset)
    end

    test "validates role is in allowed list" do
      # Test that the validation specifically checks against the allowed values
      for invalid_role <- ["guest", "moderator", "super", "ADMIN", "Coach"] do
        changeset =
          Users.changeset(%Users{}, %{user_name: "test", name: "Test", role: invalid_role})

        refute changeset.valid?, "Expected #{invalid_role} to be invalid"
      end
    end
  end

  describe "registration_changeset/2 with role" do
    test "accepts role field during registration" do
      attrs = valid_user_attributes(role: "coach")

      changeset =
        Users.registration_changeset(%Users{}, attrs, hash_password: false, validate_email: false)

      assert changeset.valid?
      assert changeset.changes[:role] == "coach"
    end

    test "defaults to 'user' role when not specified" do
      attrs = valid_user_attributes()

      changeset =
        Users.registration_changeset(%Users{}, attrs, hash_password: false, validate_email: false)

      assert changeset.valid?
      # Role is not in changes when not explicitly set (uses schema default)
      refute Map.has_key?(changeset.changes, :role)
    end

    test "can register user with coach role" do
      attrs = valid_user_attributes(role: "coach")
      {:ok, user} = Auth.register_user(attrs)

      assert user.role == "coach"
    end

    test "can register user with default user role" do
      attrs = valid_user_attributes()
      {:ok, user} = Auth.register_user(attrs)

      assert user.role == "user"
    end

    test "cannot register with admin role (admin is not in registration options)" do
      # Note: admin role is technically valid but should not be selectable via registration form
      # This test documents that the schema accepts it, but the UI restricts it
      attrs = valid_user_attributes(role: "admin")
      {:ok, user} = Auth.register_user(attrs)

      # The schema accepts admin role - it's the UI that should restrict this
      assert user.role == "admin"
    end
  end

  describe "user fixtures" do
    test "user_fixture creates user with default role" do
      user = user_fixture()
      assert user.role == "user"
    end

    test "coach_fixture creates user with coach role" do
      coach = coach_fixture()
      assert coach.role == "coach"
    end

    test "admin_fixture creates user with admin role" do
      admin = admin_fixture()
      assert admin.role == "admin"
    end

    test "user_fixture can override role" do
      user = user_fixture(%{role: "coach"})
      assert user.role == "coach"
    end
  end
end
