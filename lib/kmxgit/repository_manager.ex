defmodule Kmxgit.RepositoryManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User

  def list_repositories do
    Repo.all from org in Repository,
      preload: [organisation: :slug],
      preload: [user: :slug]
  end

  def change_repository(repository \\ %Repository{}) do
    Repository.changeset(repository, %{})
  end

  def create_repository(owner), do: create_repository(owner, %{})

  def create_repository(user = %User{}, attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def create_repository(org = %Organisation{}, attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:organisation, org)
    |> Repo.insert()
  end

  def update_repository(repository, attrs \\ %{}) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
  end

  def get_repository(id) do
    Repo.one(from repo in Repository,
      where: repo.id == ^id,
      limit: 1,
      preload: [members: :slug,
                organisation: [:slug, [users: :slug]],
                user: :slug])
  end

  def get_repository!(id) do
    get_repository(id) || raise Ecto.NoResultsError
  end

  def get_repository_by_owner_and_slug(owner, slug) do
    downcase_owner = String.downcase(owner)
    downcase_slug = String.downcase(slug)
    Repo.one from r in Repository,
      full_join: o in Organisation,
      on: o.id == r.organisation_id,
      full_join: os in Slug,
      on: os.organisation_id == o.id,
      full_join: u in User,
      on: u.id == r.user_id,
      full_join: us in Slug,
      on: us.user_id == u.id,
      where: (fragment("lower(?)", os.slug) == ^downcase_owner or fragment("lower(?)", us.slug) == ^downcase_owner) and fragment("lower(?)", r.slug) == ^downcase_slug,
      preload: [members: :slug,
                organisation: [:slug, [users: :slug]],
                user: :slug]
  end

  def add_member(%Repository{} = repo, login) do
    user = UserManager.get_user_by_slug(login)
    if user do
      members = [user | repo.members]
      IO.inspect(members)
      repo
      |> Repository.changeset(%{})
      |> Ecto.Changeset.put_assoc(:members, members)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def remove_member(%Repository{} = repo, login) do
    user = UserManager.get_user_by_slug(login)
    if user do
      members = Enum.reject(repo.members, &(&1.id == user.id))
      repo
      |> Repository.changeset(%{})
      |> Ecto.Changeset.put_assoc(:members, members)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def delete_repository(%Repository{} = repo) do
    Repo.delete(repo)
  end
end
