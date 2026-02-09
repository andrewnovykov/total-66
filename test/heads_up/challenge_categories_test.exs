defmodule HeadsUp.ChallengeCategoriesTest do
  use HeadsUp.DataCase

  alias HeadsUp.Challenges
  alias HeadsUp.Challenges.ChallengeCategory
  alias HeadsUp.AuthFixtures

  describe "challenge categories" do
    setup do
      admin = AuthFixtures.admin_fixture()
      user = AuthFixtures.user_fixture()
      %{admin: admin, user: user}
    end

    test "list_categories/0 returns all categories", %{admin: admin} do
      {:ok, cat1} = Challenges.create_category(%{name: "Fitness"}, admin)
      {:ok, cat2} = Challenges.create_category(%{name: "Learning"}, admin)

      categories = Challenges.list_categories()
      assert length(categories) == 2
      assert Enum.any?(categories, &(&1.id == cat1.id))
      assert Enum.any?(categories, &(&1.id == cat2.id))
    end

    test "list_active_categories/0 returns only active categories", %{admin: admin} do
      {:ok, active_cat} = Challenges.create_category(%{name: "Active", status: :active}, admin)

      {:ok, inactive_cat} =
        Challenges.create_category(%{name: "Inactive", status: :inactive}, admin)

      categories = Challenges.list_active_categories()
      assert length(categories) == 1
      assert hd(categories).id == active_cat.id
      refute Enum.any?(categories, &(&1.id == inactive_cat.id))
    end

    test "get_category!/1 returns the category", %{admin: admin} do
      {:ok, category} = Challenges.create_category(%{name: "Test"}, admin)
      assert Challenges.get_category!(category.id).id == category.id
    end

    test "create_category/2 allows admin to create category", %{admin: admin} do
      attrs = %{name: "New Category", description: "A test category"}
      assert {:ok, %ChallengeCategory{} = category} = Challenges.create_category(attrs, admin)
      assert category.name == "New Category"
      assert category.description == "A test category"
    end

    test "create_category/2 prevents non-admin from creating category", %{user: user} do
      attrs = %{name: "Blocked Category"}
      assert {:error, :unauthorized} = Challenges.create_category(attrs, user)
    end

    test "update_category/3 allows admin to update category", %{admin: admin} do
      {:ok, category} = Challenges.create_category(%{name: "Original"}, admin)
      assert {:ok, updated} = Challenges.update_category(category, %{name: "Updated"}, admin)
      assert updated.name == "Updated"
    end

    test "update_category/3 prevents non-admin from updating category", %{
      admin: admin,
      user: user
    } do
      {:ok, category} = Challenges.create_category(%{name: "Test"}, admin)

      assert {:error, :unauthorized} =
               Challenges.update_category(category, %{name: "Hacked"}, user)
    end

    test "delete_category/2 allows admin to delete category", %{admin: admin} do
      {:ok, category} = Challenges.create_category(%{name: "To Delete"}, admin)
      assert {:ok, _} = Challenges.delete_category(category, admin)
      assert_raise Ecto.NoResultsError, fn -> Challenges.get_category!(category.id) end
    end

    test "delete_category/2 prevents non-admin from deleting category", %{
      admin: admin,
      user: user
    } do
      {:ok, category} = Challenges.create_category(%{name: "Protected"}, admin)
      assert {:error, :unauthorized} = Challenges.delete_category(category, user)
      assert Challenges.get_category!(category.id)
    end

    test "change_category/2 returns a changeset", %{admin: admin} do
      {:ok, category} = Challenges.create_category(%{name: "Test"}, admin)
      changeset = Challenges.change_category(category, %{name: "Changed"})
      assert %Ecto.Changeset{} = changeset
    end

    test "categories are ordered by order field and name", %{admin: admin} do
      {:ok, _cat_c} = Challenges.create_category(%{name: "Zzz Last", order: 2}, admin)
      {:ok, _cat_a} = Challenges.create_category(%{name: "Aaa First", order: 1}, admin)
      {:ok, _cat_b} = Challenges.create_category(%{name: "Bbb Second", order: 1}, admin)

      categories = Challenges.list_categories()
      names = Enum.map(categories, & &1.name)

      # Order 1 comes before order 2, and alphabetically within same order
      assert names == ["Aaa First", "Bbb Second", "Zzz Last"]
    end

    test "category name must be unique", %{admin: admin} do
      {:ok, _} = Challenges.create_category(%{name: "Unique"}, admin)
      assert {:error, changeset} = Challenges.create_category(%{name: "Unique"}, admin)
      assert {"has already been taken", _} = changeset.errors[:name]
    end
  end
end
