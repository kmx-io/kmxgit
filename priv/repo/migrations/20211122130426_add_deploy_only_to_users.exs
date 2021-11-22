defmodule Kmxgit.Repo.Migrations.AddDeployOnlyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :deploy_only, :boolean, null: false, default: false
    end
  end
end
