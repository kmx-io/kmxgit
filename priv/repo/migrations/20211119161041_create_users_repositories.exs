defmodule Kmxgit.Repo.Migrations.CreateUsersRepositories do
  use Ecto.Migration

  def change do
    create table(:users_repositories, foreign_key: false) do
      add :user_id, references(:users)
      add :repository_id, references(:repositories)
    end
  end
end
