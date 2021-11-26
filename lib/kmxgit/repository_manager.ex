defmodule Kmxgit.RepositoryManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User

  def list_repositories do
    Repo.all(from r in Repository,
      preload: [members: :slug,
                organisation: [:slug, users: :slug],
                user: :slug])
    |> Enum.sort_by(fn x -> Repository.full_slug(x) end)
  end

  def change_repository(repository \\ %Repository{}) do
    Repository.changeset(repository, %{})
  end

  defp put_owner(changeset, owner) do
    case owner do
      %User{} ->
        Ecto.Changeset.put_assoc(changeset, :user, owner)
      %Organisation{} ->
        Ecto.Changeset.put_assoc(changeset, :organisation, owner)
    end
  end

  def create_repository(owner, attrs \\ %{}) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> put_owner(owner)
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
