defmodule Kmxgit.Repo.Migrations.AddDiskUsageToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :disk_usage, :integer, default: 0
    end
  end
end
