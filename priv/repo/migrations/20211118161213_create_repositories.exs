defmodule Kmxgit.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :slug, :string
      add :description, :string
      add :organisation_id, references(:organisations), null: true
      add :user_id, references(:users), null: true
      timestamps()
    end
  end
end
