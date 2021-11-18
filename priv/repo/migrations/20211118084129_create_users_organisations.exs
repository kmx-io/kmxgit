defmodule Kmxgit.Repo.Migrations.CreateUsersOrganisations do
  use Ecto.Migration

  def change do
    create table(:users_organisations, foreign_key: false) do
      add :user_id, references(:users)
      add :organisation_id, references(:organisations)
    end
  end
end
