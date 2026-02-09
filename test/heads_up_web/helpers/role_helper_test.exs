defmodule HeadsUpWeb.Helpers.RoleHelperTest do
  use ExUnit.Case, async: true

  alias HeadsUpWeb.Helpers.RoleHelper

  describe "valid_roles/0" do
    test "returns list of valid roles" do
      assert RoleHelper.valid_roles() == ["user", "coach", "admin"]
    end
  end

  describe "is_admin?/1" do
    test "returns true for admin role" do
      assert RoleHelper.is_admin?(%{role: "admin"}) == true
    end

    test "returns false for coach role" do
      assert RoleHelper.is_admin?(%{role: "coach"}) == false
    end

    test "returns false for user role" do
      assert RoleHelper.is_admin?(%{role: "user"}) == false
    end

    test "returns false for nil" do
      assert RoleHelper.is_admin?(nil) == false
    end

    test "returns false for invalid role" do
      assert RoleHelper.is_admin?(%{role: "invalid"}) == false
    end
  end

  describe "is_coach?/1" do
    test "returns true for coach role" do
      assert RoleHelper.is_coach?(%{role: "coach"}) == true
    end

    test "returns false for admin role" do
      assert RoleHelper.is_coach?(%{role: "admin"}) == false
    end

    test "returns false for user role" do
      assert RoleHelper.is_coach?(%{role: "user"}) == false
    end

    test "returns false for nil" do
      assert RoleHelper.is_coach?(nil) == false
    end
  end

  describe "is_coach_or_admin?/1" do
    test "returns true for coach role" do
      assert RoleHelper.is_coach_or_admin?(%{role: "coach"}) == true
    end

    test "returns true for admin role" do
      assert RoleHelper.is_coach_or_admin?(%{role: "admin"}) == true
    end

    test "returns false for user role" do
      assert RoleHelper.is_coach_or_admin?(%{role: "user"}) == false
    end

    test "returns false for nil" do
      assert RoleHelper.is_coach_or_admin?(nil) == false
    end

    test "returns false for invalid role" do
      assert RoleHelper.is_coach_or_admin?(%{role: "invalid"}) == false
    end
  end

  describe "is_user?/1" do
    test "returns true for user role" do
      assert RoleHelper.is_user?(%{role: "user"}) == true
    end

    test "returns false for coach role" do
      assert RoleHelper.is_user?(%{role: "coach"}) == false
    end

    test "returns false for admin role" do
      assert RoleHelper.is_user?(%{role: "admin"}) == false
    end

    test "returns false for nil" do
      assert RoleHelper.is_user?(nil) == false
    end
  end

  describe "has_role_at_least?/2" do
    test "admin has at least user role" do
      assert RoleHelper.has_role_at_least?(%{role: "admin"}, "user") == true
    end

    test "admin has at least coach role" do
      assert RoleHelper.has_role_at_least?(%{role: "admin"}, "coach") == true
    end

    test "admin has at least admin role" do
      assert RoleHelper.has_role_at_least?(%{role: "admin"}, "admin") == true
    end

    test "coach has at least user role" do
      assert RoleHelper.has_role_at_least?(%{role: "coach"}, "user") == true
    end

    test "coach has at least coach role" do
      assert RoleHelper.has_role_at_least?(%{role: "coach"}, "coach") == true
    end

    test "coach does not have admin role" do
      assert RoleHelper.has_role_at_least?(%{role: "coach"}, "admin") == false
    end

    test "user has at least user role" do
      assert RoleHelper.has_role_at_least?(%{role: "user"}, "user") == true
    end

    test "user does not have coach role" do
      assert RoleHelper.has_role_at_least?(%{role: "user"}, "coach") == false
    end

    test "user does not have admin role" do
      assert RoleHelper.has_role_at_least?(%{role: "user"}, "admin") == false
    end

    test "returns false for nil user" do
      assert RoleHelper.has_role_at_least?(nil, "user") == false
    end

    test "handles invalid roles gracefully" do
      assert RoleHelper.has_role_at_least?(%{role: "invalid"}, "user") == false
    end
  end

  describe "integration with structs" do
    test "works with user-like structs" do
      user = %{id: 1, email: "test@example.com", role: "admin"}
      assert RoleHelper.is_admin?(user) == true
      assert RoleHelper.is_coach_or_admin?(user) == true
    end

    test "works with maps containing extra fields" do
      user = %{id: 1, name: "Test", email: "test@example.com", role: "coach", extra: "data"}
      assert RoleHelper.is_coach?(user) == true
      assert RoleHelper.is_coach_or_admin?(user) == true
      assert RoleHelper.is_admin?(user) == false
    end
  end
end
