# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :kmxgit,
  recaptcha_site_key: System.get_env("RECAPTCHA_SITE_KEY"),
  recaptcha_secret: System.get_env("RECAPTCHA_SECRET"),
  ssh_url: "git@git.kmx.io",
  ecto_repos: [Kmxgit.Repo]

# Configures the endpoint
config :kmxgit, KmxgitWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: KmxgitWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Kmxgit.PubSub,
  live_view: [signing_salt: "0HhihW2z"]

config :dart_sass,
  version: "1.39.0",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :kmxgit, Kmxgit.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :kmxgit, Kmxgit.UserManager.Guardian,
  issuer: "kmxgit",
  secret_key: File.read!("config/.guardian.secret_key")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
