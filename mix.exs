defmodule Kmxgit.MixProject do
  use Mix.Project

  def project do
    [
      app: :kmxgit,
      version: "0.4.0",
      version_url: "https://git.kmx.io/kmx.io/kmxgit/_tree/master",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Kmxgit.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:dart_sass, git: "https://github.com/kmx-io/dart_sass", only: :dev},
      {:earmark, "~> 1.4.5"},
      {:ecto_sql, "~> 3.6"},
      {:elixir_auth_google, "~> 1.6.2"},
      {:esbuild, "~> 0.4", only: :dev},
      {:exgravatar, "~> 2.0"},
      {:file_size, "~> 3.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:gen_smtp, "~> 1.1"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:mogrify, "~> 0.9.1"},
      {:phoenix, "~> 1.6.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.0"},
      {:plug_cowboy, "~> 2.5"},
      {:plug_recaptcha, git: "https://github.com/thodg/plug_recaptcha.git"},
      {:postgrex, ">= 0.0.0"},
      {:pot, "~> 1.0"},
      {:qrcode_ex, "~> 0.1.0"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "esbuild assets/js/app.js priv/static/_assets/app.js --minify",
	"sass assets/css/app.scss priv/static/_assets/app.css --no-source-map --style=compressed",
        "phx.digest"
      ]
    ]
  end
end
