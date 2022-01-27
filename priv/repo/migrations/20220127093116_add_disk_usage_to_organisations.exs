defmodule Kmxgit.Repo.Migrations.AddDiskUsageToOrganisations do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      add :disk_usage, :integer, default: 0
    end
  end
end
