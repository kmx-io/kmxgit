import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
    "ecto://git:L4GNDeg+UAlsBYnX@localhost/git"

  config :kmxgit, Kmxgit.Repo,
    # ssl: true,
    # socket_options: [:inet6],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
    queue_target: 5000

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :kmxgit, KmxgitWeb.Endpoint,
    http: [
      ip: {127, 0, 0, 1},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :kmxgit, KmxgitWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  config :kmxgit, Kmxgit.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: "127.0.0.1",
    retries: 2,
    no_mx_lookups: true
end
