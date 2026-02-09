defmodule HeadsUp.AuthFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.Auth` context.
  """

  def unique_user_email do
    uniq = System.unique_integer([:positive, :monotonic])
    "user-#{System.system_time(:microsecond)}-#{uniq}@example.com"
  end

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive, :monotonic])

    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      user_name: "testuser#{unique_id}",
      name: "Test User #{unique_id}"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HeadsUp.Auth.register_user()

    user
  end

  @doc """
  Creates a user with coach role.
  """
  def coach_fixture(attrs \\ %{}) do
    user_fixture(Map.put(attrs, :role, "coach"))
  end

  @doc """
  Creates a user with admin role.
  """
  def admin_fixture(attrs \\ %{}) do
    user_fixture(Map.put(attrs, :role, "admin"))
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
