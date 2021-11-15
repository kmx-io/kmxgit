defmodule Kmxgit.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :description, :string
      add :email, :string
      add :encrypted_password, :string
      add :is_admin, :boolean, null: false, default: false
      add :login, :string
      add :name, :string
      timestamps()
    end
    create index(:users, ["(lower(login))"], unique: true)
    create index(:users, ["(lower(email))"], unique: true)
  end
end
