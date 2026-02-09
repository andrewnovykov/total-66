defmodule HeadsUpWeb.Router do
  use HeadsUpWeb, :router

  import HeadsUpWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HeadsUpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_user
    plug HeadsUpWeb.Plugs.ApiAuth
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :require_authenticated_user_api
  end

  scope "/", HeadsUpWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Public pages - accessible to everyone (guests and authenticated users)
    live_session :public,
      on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
      live "/people", UsersLive.Index
      live "/people/:username", UsersLive.Show
      # Challenges - browsing and viewing (new/edit require auth in LiveView)
      live "/challenges", ChallengeLive.Index
      live "/challenges/new", ChallengeLive.New
      live "/challenges/:id", ChallengeLive.Show
      live "/challenges/:id/edit", ChallengeLive.Edit
    end
  end

  scope "/", HeadsUpWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Authenticated-only pages
    live_session :authenticated,
      on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
      live "/my-challenges", ChallengeLive.MyChallenges
      live "/connections", ConnectionsLive.Index
      live "/feed", FeedLive.Index
      live "/messages", MessagesLive.Index
      live "/messages/:id", MessagesLive.Show
    end
  end

  scope "/coach", HeadsUpWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Coach-only pages (accessible by coaches and admins)
    live_session :coach,
      on_mount: [
        {HeadsUpWeb.UserAuth, :ensure_authenticated},
        {HeadsUpWeb.CoachAuth, :ensure_coach}
      ] do
      # Coach-specific pages will be added here
      # live "/dashboard", Coach.DashboardLive.Index
    end
  end

  scope "/admin", HeadsUpWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Admin-only pages
    live_session :admin,
      on_mount: [
        {HeadsUpWeb.UserAuth, :ensure_authenticated},
        {HeadsUpWeb.AdminAuth, :ensure_admin}
      ] do
      live "/challenge-categories", Admin.ChallengeCategoriesLive.Index
    end
  end

  # Other scopes may use custom stacks.
  scope "/api", HeadsUpWeb.Api, as: :api do
    pipe_through :api

    # Public auth endpoints for mobile clients
    scope "/auth" do
      # POST /api/auth/register - Register new user
      post "/register", AuthController, :register
      # POST /api/auth/login - Login with JSON credentials
      post "/login", AuthController, :login
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:heads_up, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HeadsUpWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HeadsUpWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HeadsUpWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HeadsUpWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HeadsUpWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # ============================================================
  # PUBLIC API Routes (no auth required)
  # ============================================================
  scope "/api", HeadsUpWeb.Api, as: :api do
    pipe_through :api

    # Public User endpoints
    scope "/users" do
      get "/", UserController, :index
      get "/username/:username", UserController, :show_by_username
    end

    # Public Challenge endpoints
    scope "/challenges" do
      get "/", ChallengeController, :index
      get "/templates", ChallengeController, :templates
      get "/categories", ChallengeController, :categories
    end
  end

  # ============================================================
  # AUTHENTICATED API Routes
  # ============================================================
  scope "/api", HeadsUpWeb.Api, as: :api do
    pipe_through [:api, :require_authenticated_user_api]

    # Auth endpoints
    scope "/auth" do
      get "/me", AuthController, :me
      delete "/logout", AuthController, :logout
    end

    # User profile management
    scope "/users" do
      put "/me", UserController, :update_profile
      patch "/me", UserController, :update_profile

      # User social actions
      post "/:id/follow", UserController, :follow
      delete "/:id/follow", UserController, :unfollow
      post "/:id/friend-request", UserController, :send_friend_request
      get "/:id/followers", UserController, :followers
      get "/:id/following", UserController, :following

      # User reporting
      post "/:id/report", ReportController, :report_user
    end

    # Friend requests management
    scope "/friend-requests" do
      get "/", UserController, :list_friend_requests
      post "/:id/accept", UserController, :accept_friend_request
      post "/:id/decline", UserController, :decline_friend_request
      delete "/:id", UserController, :cancel_friend_request
    end

    # Friends management
    scope "/friends" do
      get "/", UserController, :list_friends
      delete "/:id", UserController, :remove_friend
    end

    # Challenges API endpoints
    scope "/challenges" do
      get "/my", ChallengeController, :my_challenges
      post "/", ChallengeController, :create
      put "/:id", ChallengeController, :update
      patch "/:id", ChallengeController, :update
      delete "/:id", ChallengeController, :delete

      # Challenge participation
      post "/:id/start", ChallengeController, :start
      post "/:id/join", ChallengeController, :join
      delete "/:id/leave", ChallengeController, :leave
      post "/:id/fail", ChallengeController, :fail
      post "/:id/cancel", ChallengeController, :cancel
      post "/:id/share", ChallengeController, :share

      # Challenge progress & daily
      get "/:id/progress", ChallengeController, :progress
      get "/:id/today", ChallengeController, :today
      get "/:id/feed", ChallengeController, :feed
      post "/:id/check-in", ChallengeController, :check_in

      # Challenge step/task completion
      post "/:id/steps/:step_id/complete", ChallengeController, :complete_step
      post "/:id/tasks/:task_id/complete", ChallengeController, :complete_task

      # Challenge reporting
      post "/:id/report", ReportController, :report_challenge
    end

    # Check-in interactions
    scope "/check-ins" do
      post "/:id/like", ChallengeController, :like_check_in
      delete "/:id/like", ChallengeController, :unlike_check_in
      post "/:id/comments", ChallengeController, :create_check_in_comment
    end

    # Activity and feed endpoints
    scope "/activities" do
      get "/:user_id", ActivityController, :user_activities
    end

    scope "/feed" do
      get "/", ActivityController, :user_feed
    end

    scope "/chart" do
      get "/:user_id", ActivityController, :chart_data
    end

    scope "/users/:user_id" do
      get "/stats", ActivityController, :user_stats
    end
  end

  # Public API Routes with catch-all :id (must be last)
  scope "/api", HeadsUpWeb.Api, as: :api do
    pipe_through :api

    scope "/users" do
      get "/:id", UserController, :show
    end

    scope "/challenges" do
      get "/:id", ChallengeController, :show
    end
  end
end
