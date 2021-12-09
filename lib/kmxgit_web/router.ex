defmodule KmxgitWeb.Router do
  use KmxgitWeb, :router

  import KmxgitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KmxgitWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :recaptcha do
    plug PlugRecaptcha2, recaptcha_secret: Application.get_env(:kmxgit, :recaptcha_secret)
  end

  pipeline :admin do
    plug Kmxgit.Plug.EnsureAdmin
    plug :put_root_layout, {KmxgitWeb.LayoutView, "admin.html"}
  end

  # maybe logged in
  scope "/", KmxgitWeb do
    pipe_through [:browser]

    get  "/",                         PageController, :index
    get  "/_etc/git/auth.conf",       PageController, :auth
    get  "/_etc/ssh/authorized_keys", PageController, :keys
    get  "/_new_admin",               PageController, :new_admin
    post "/_new_admin",               PageController, :new_admin_post

    delete "/users/log_out",        UserSessionController, :delete
    get    "/users/confirm",        UserConfirmationController, :new
    post   "/users/confirm",        UserConfirmationController, :create
    get    "/users/confirm/:token", UserConfirmationController, :edit
    post   "/users/confirm/:token", UserConfirmationController, :update
  end

    ## Authentication routes

  scope "/", KmxgitWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/log_in", UserSessionController, :new
    get "/users/register", UserRegistrationController, :new
    get "/users/reset_password", UserResetPasswordController, :new
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update

    pipe_through :recaptcha
    post "/users/log_in", UserSessionController, :create
    post "/users/register", UserRegistrationController, :create
    post "/users/reset_password", UserResetPasswordController, :create
  end

  scope "/", KmxgitWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    scope "/_new" do
      get  "/organisation", OrganisationController, :new
      post "/organisation", OrganisationController, :create
      get  "/repository/:owner", RepositoryController, :new
      post "/repository/:owner", RepositoryController, :create
    end

    scope "/_edit/" do
      get "/organisation/:slug", OrganisationController, :edit
      put "/organisation/:slug", OrganisationController, :update
      get "/user/:login", UserController, :edit
      put "/user/:login", UserController, :update
      get "/repository/:owner/*slug", RepositoryController, :edit
      put "/repository/:owner/*slug", RepositoryController, :update
    end

    scope "/_add_user/" do
      get  "/:slug", OrganisationController, :add_user
      post "/:slug", OrganisationController, :add_user_post
      get  "/:owner/*slug", RepositoryController, :add_user
      post "/:owner/*slug", RepositoryController, :add_user_post
    end

    scope "/_remove_user/" do
      get  "/:slug", OrganisationController, :remove_user
      post "/:slug", OrganisationController, :remove_user_post
      get  "/:owner/*slug", RepositoryController, :remove_user
      post "/:owner/*slug", RepositoryController, :remove_user_post
    end

    scope "/_delete/" do
      delete "/organisation/:slug",      OrganisationController, :delete
      delete "/user/:login",             UserController, :delete
      delete "/repository/:owner/*slug", RepositoryController, :delete
    end

    scope "/_fork/" do
      get  "/:owner/*slug", RepositoryController, :fork
      post "/:owner/*slug", RepositoryController, :fork_post
    end

    scope "/_admin", Admin, as: "admin" do
      pipe_through :admin
      get "/", DashboardController, :index
      resources "/organisations", OrganisationController do
        get  "/add_user/",   OrganisationController, :add_user, as: :""
        post "/add_user",    OrganisationController, :add_user_post, as: :""
        get  "/remove_user", OrganisationController, :remove_user, as: :""
        post "/remove_user", OrganisationController, :remove_user_post, as: :""
      end
      resources "/repositories", RepositoryController do
        get  "/add_user",    RepositoryController, :add_user, as: :""
        post "/add_user",    RepositoryController, :add_user_post, as: :""
        get  "/remove_user", RepositoryController, :remove_user, as: :""
        post "/remove_user", RepositoryController, :remove_user_post, as: :""
      end
      resources "/users", UserController do
        get "/password/edit", UserController, :edit_password, as: :""
        put "/password",      UserController, :update_password, as: :""
      end

      import Phoenix.LiveDashboard.Router
      live_dashboard "/dashboard", metrics: KmxgitWeb.Telemetry
    end

    get "/:slug", SlugController, :show
    get "/:owner/*slug", RepositoryController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", KmxgitWeb do
  #   pipe_through :api
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
