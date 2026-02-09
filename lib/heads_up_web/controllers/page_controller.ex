defmodule HeadsUpWeb.PageController do
  use HeadsUpWeb, :controller
  alias HeadsUp.Repo
  import Ecto.Query

  def home(conn, _params) do
    user_count = Repo.aggregate(HeadsUp.Users, :count, :id)

    finisher_count =
      from(cp in HeadsUp.Challenges.ChallengeParticipant,
        where: cp.status == :completed,
        select: count(cp.user_id, :distinct)
      )
      |> Repo.one()

    conn
    |> put_layout(html: false)
    |> assign(:user_count, user_count)
    |> assign(:finisher_count, finisher_count)
    |> render(:home)
  end
end
