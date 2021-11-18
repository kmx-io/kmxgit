defmodule Kmxgit.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add :description, :string
      add :name, :string
      timestamps()
    end
  end
end
