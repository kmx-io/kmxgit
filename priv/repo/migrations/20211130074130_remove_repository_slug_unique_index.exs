defmodule Kmxgit.Repo.Migrations.RemoveRepositorySlugUniqueIndex do
  use Ecto.Migration

  def up do
    drop_if_exists index(:repositories, ["(lower(slug))"], unique: true)
  end

  def down do
  end
end
