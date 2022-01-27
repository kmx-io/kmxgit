defmodule Kmxgit.Repo.Migrations.AddDiskUsageToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :disk_usage, :integer, default: 0
    end
  end
end
