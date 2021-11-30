defmodule Kmxgit.Repo.Migrations.AddDeployKeysToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :deploy_keys, :text
    end
  end
end
