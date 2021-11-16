defmodule Kmxgit.Repo.Migrations.AddSshKeysToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ssh_keys, :text
    end
  end
end
