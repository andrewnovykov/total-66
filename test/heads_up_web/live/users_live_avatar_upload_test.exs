defmodule HeadsUpWeb.UsersLive.AvatarUploadTest do
  use HeadsUpWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias HeadsUp.{Accounts, AuthFixtures}

  describe "avatar upload on profile page" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()

      %{conn: log_in_user(conn, user), user: user}
    end

    test "owner can upload avatar and save it", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/people/#{user.user_name}")

      view
      |> element("button[phx-click='edit_avatar']")
      |> render_click()

      assert has_element?(view, "form[phx-submit='save_avatar']")
      assert render(view) =~ "drag and drop"
      assert render(view) =~ "phx-drop-target"

      upload =
        file_input(view, "form[phx-submit='save_avatar']", :avatar, [
          %{
            name: "avatar.png",
            content: File.read!("priv/static/images/user-1.png"),
            type: "image/png"
          }
        ])

      assert render_upload(upload, "avatar.png") =~ "100%"

      view
      |> form("form[phx-submit='save_avatar']")
      |> render_submit()

      assert render(view) =~ "Avatar updated successfully"

      updated_user = Accounts.get_user(user.id)
      assert updated_user.image_path =~ "/uploads/avatar_"

      uploaded_file =
        Path.join("priv/static", String.trim_leading(updated_user.image_path, "/"))

      if File.exists?(uploaded_file) do
        File.rm(uploaded_file)
      end
    end
  end

  test "uploads are exposed in static paths" do
    assert "uploads" in HeadsUpWeb.static_paths()
  end
end
