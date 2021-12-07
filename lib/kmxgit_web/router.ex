defmodule KmxgitWeb.Router do
  use KmxgitWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KmxgitWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :recaptcha do
    plug PlugRecaptcha2, recaptcha_secret: Application.get_env(:kmxgit, :recaptcha_secret)
  end

  # Our pipeline implements "maybe" authenticated. We'll use the `:ensure_auth` below for when we need to make sure someone is logged in.
  pipeline :auth do
    plug Kmxgit.UserManager.Pipeline
  end

# We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :admin do
    plug Kmxgit.Plug.EnsureAdmin
    plug :put_root_layout, {KmxgitWeb.LayoutView, "admin.html"}
  end

  # maybe logged in
  scope "/", KmxgitWeb do
    pipe_through [:browser, :auth]

    get  "/",                         PageController, :index
    get  "/_etc/git/auth.conf",       PageController, :auth
    get  "/_etc/ssh/authorized_keys", PageController, :keys
    get  "/_new_admin",               PageController, :new_admin
    post "/_new_admin",               PageController, :new_admin_post

    scope "/_sessions" do
      get  "/new",    SessionController, :new
      get  "/logout", SessionController, :logout

      pipe_through :recaptcha
      post "/new",    SessionController, :login
    end

    get  "/_register", RegistrationController, :new

    pipe_through :recaptcha
    post "/_register", RegistrationController, :register
  end

  # definitely logged in, will redirect to login page
  scope "/", KmxgitWeb do
    pipe_through [:browser, :auth, :ensure_auth]

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
      resources "/users", UserController

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
