defmodule Kmxgit.Repo.Migrations.Slug do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      add :slug_, :citext
    end
    alter table(:users) do
      add :slug_, :citext
    end
    alter table(:slugs) do
      modify :slug, :citext, null: false
    end
  end
end
