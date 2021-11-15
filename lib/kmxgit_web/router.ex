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

    get "/",           PageController, :index
    get  "/new_admin", PageController, :new_admin
    post "/new_admin", PageController, :new_admin_post

    scope "/sessions" do
      get  "/new",    SessionController, :new
      post "/new",    SessionController, :login
      get  "/logout", SessionController, :logout
    end

    get "/register",  RegistrationController, :new
    post "/register", RegistrationController, :register
  end

  # definitely logged in, will redirect to login page
  scope "/", KmxgitWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    scope "/org" do
      get "/",      OrganisationController, :index
      get "/:slug", OrganisationController, :show
    end

    scope "/u" do
      get "/:login",      UserController, :show
      get "/:login/edit", UserController, :edit
      put "/:login",      UserController, :update
    end

    scope "/admin", Admin, as: "admin" do
      pipe_through :admin
      get "/", DashboardController, :index
      resources "/org", OrganisationController
      resources "/u", UserController

      import Phoenix.LiveDashboard.Router
      live_dashboard "/dashboard", metrics: KmxgitWeb.Telemetry
    end
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
