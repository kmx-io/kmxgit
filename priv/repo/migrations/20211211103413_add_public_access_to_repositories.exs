defmodule Kmxgit.Repo.Migrations.AddPublicAccessToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :public_access, :boolean, null: false, default: false
    end
  end
end
