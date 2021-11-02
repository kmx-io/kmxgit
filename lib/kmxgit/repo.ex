defmodule Kmxgit.Repo do
  use Ecto.Repo,
    otp_app: :kmxgit,
    adapter: Ecto.Adapters.Postgres
end
