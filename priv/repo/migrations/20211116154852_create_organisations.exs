defmodule Kmxgit.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add :description, :string
      add :name, :string
      add :slug, :string, null: false
      timestamps()
    end
    create index(:organisations, ["(lower(slug))"], unique: true)
  end
end
