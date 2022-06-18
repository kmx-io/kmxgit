defmodule Kmxgit.Repo.Migrations.Slug2 do
  use Ecto.Migration

  def change do
    drop index(:slugs, ["(lower(slug))"], unique: true)
    create index(:slugs, [:slug], unique: true)
  end
end
