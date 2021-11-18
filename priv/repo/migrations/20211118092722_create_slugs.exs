defmodule Kmxgit.Repo.Migrations.CreateSlugs do
  use Ecto.Migration

  def change do
    create table(:slugs) do
      add :slug, :string, unique: true
      add :organisation_id, references(:organisations), null: true
      add :user_id, references(:users), null: true
      timestamps()
    end
    create index(:slugs, ["(lower(slug))"], unique: true)
  end
end
