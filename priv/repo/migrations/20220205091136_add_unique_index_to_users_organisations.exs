defmodule Kmxgit.Repo.Migrations.AddUniqueIndexToUsersOrganisations do
  use Ecto.Migration

  def change do
    create index(:users_organisations, [:user_id, :organisation_id], unique: true)
  end
end
