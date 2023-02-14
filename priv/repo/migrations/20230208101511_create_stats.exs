defmodule Kmxgit.Repo.Migrations.CreateStats do
  use Ecto.Migration

  def change do
    create table("url_views") do
      add :url, :string
      add :slug_id, references(:slugs)
      add :repo_id, references(:repositories)
      add :response_time, :time
      add :inserted_at, :naive_datetime
    end
  end
end
