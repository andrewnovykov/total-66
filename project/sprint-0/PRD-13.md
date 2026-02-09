we have
GET /api/goals HeadsUpWeb.Api.GoalController :index
GET /api/goals/category/:category_id HeadsUpWeb.Api.GoalController :by_category
GET /api/auth/me HeadsUpWeb.Api.AuthController :me
DELETE /api/auth/logout HeadsUpWeb.Api.AuthController :logout
GET /api/goals/my HeadsUpWeb.Api.GoalController :my_goals
POST /api/goals HeadsUpWeb.Api.GoalController :create
PUT /api/goals/:id HeadsUpWeb.Api.GoalController :update
PATCH /api/goals/:id HeadsUpWeb.Api.GoalController :update
DELETE /api/goals/:id HeadsUpWeb.Api.GoalController :delete
POST /api/goals/:id/like HeadsUpWeb.Api.GoalController :like
DELETE /api/goals/:id/like HeadsUpWeb.Api.GoalController :unlike
POST /api/goals/:id/subscribe HeadsUpWeb.Api.GoalController :subscribe
DELETE /api/goals/:id/subscribe HeadsUpWeb.Api.GoalController :unsubscribe
POST /api/goals/:id/restore HeadsUpWeb.Api.GoalController :restore
POST /api/goals/:id/fail HeadsUpWeb.Api.GoalController :fail
POST /api/goals/:id/freeze HeadsUpWeb.Api.GoalController :freeze
POST /api/goals/:id/unfreeze HeadsUpWeb.Api.GoalController :unfreeze
GET /api/goals/deleted HeadsUpWeb.Api.GoalController :deleted_goals
POST /api/users/:id/follow HeadsUpWeb.Api.UserController :follow
DELETE /api/users/:id/follow HeadsUpWeb.Api.UserController :unfollow
POST /api/users/:id/friend-request HeadsUpWeb.Api.UserController :send_friend_request
GET /api/friend-requests HeadsUpWeb.Api.UserController :list_friend_requests
POST /api/friend-requests/:id/accept HeadsUpWeb.Api.UserController :accept_friend_request
POST /api/friend-requests/:id/decline HeadsUpWeb.Api.UserController :decline_friend_request
DELETE /api/friend-requests/:id HeadsUpWeb.Api.UserController :cancel_friend_request
GET /api/friends HeadsUpWeb.Api.UserController :list_friends
DELETE /api/friends/:id HeadsUpWeb.Api.UserController :remove_friend
POST /api/admin/categories HeadsUpWeb.Api.CategoryController :create
PUT /api/admin/categories/:id HeadsUpWeb.Api.CategoryController :update
PATCH /api/admin/categories/:id HeadsUpWeb.Api.CategoryController :update
DELETE /api/admin/categories/:id HeadsUpWeb.Api.CategoryController :delete
GET /api/activities/:user_id HeadsUpWeb.Api.ActivityController :user_activities
GET /api/feed HeadsUpWeb.Api.ActivityController :user_feed
GET /api/chart/:user_id HeadsUpWeb.Api.ActivityController :chart_data
GET /api/users/:user_id/stats HeadsUpWeb.Api.ActivityController :user_stats
GET /api/goals/:id HeadsUpWeb.Api.GoalController :show

we need create api for all what we build right now. we dont need api. for /admin. but everithing that related to users, and logen users, we need build api . also registration. after registration users should login and get token. with this token user can do what loged user .
On the end create api doc in project_doc/docs/specifications/api-endpoints.md

rewrite this prd ! but its done !
