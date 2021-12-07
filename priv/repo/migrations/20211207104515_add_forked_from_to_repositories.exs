defmodule Kmxgit.Repo.Migrations.AddForkedFromToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :forked_from_id, references(:repositories)
    end
    create index(:repositories, [:forked_from_id])
  end
end
