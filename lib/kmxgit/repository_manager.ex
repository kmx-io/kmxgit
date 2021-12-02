defmodule Kmxgit.RepositoryManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User

  def list_repositories do
    Repo.all(from r in Repository,
      preload: [members: :slug,
                organisation: [:slug, users: :slug],
                user: :slug])
    |> Enum.sort_by(&Repository.full_slug/1)
  end

  def list_contributor_repositories(user) do
    list_repositories()
    |> Enum.filter(fn repo ->
      (!repo.user || repo.user.id != user.id) &&
      (Repository.members(repo)
       |> Enum.find(fn u -> u.id == user.id end))
    end)
  end

  def change_repository() do
    change_repository(%Repository{})
  end
  def change_repository(repository = %Repository{}) do
    Repository.changeset(repository, %{})
  end
  def change_repository(owner) do
    change_repository(%Repository{}, owner)
  end
  def change_repository(repository = %Repository{}, owner = %Organisation{}) do
    Repository.owner_changeset(repository, %{}, owner)
  end
  def change_repository(repository = %Repository{}, owner = %User{}) do
    Repository.owner_changeset(repository, %{}, owner)
  end

  def create_repository(attrs \\ %{}, owner) do
    %Repository{}
    |> Repository.owner_changeset(attrs, owner)
    |> Repo.insert()
  end

  def update_repository(repository, attrs = %{"owner_slug" => owner_slug}) do
    if owner_slug && owner_slug != "" do
      if slug = SlugManager.get_slug(owner_slug) do
        owner = slug.organisation || slug.user
        IO.inspect([owner_slug: owner_slug, slug: slug, owner: owner])
        repository
        |> Repository.owner_changeset(attrs, owner)
        |> Repo.update()
      else
        changeset = repository
        |> Repository.changeset(attrs)
        |> Ecto.Changeset.add_error(:owner_slug, "not found")
        {:error, %Ecto.Changeset{changeset | action: :update}}
      end
    else
      repository
      |> Repository.changeset(attrs)
      |> Repo.update()
    end
  end
  def update_repository(repository, attrs) do
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

  def get_repository_by_owner_id_and_slug(org_id, nil, slug) do
    Repo.one from r in Repository,
      where: r.organisation_id == ^org_id and is_nil(r.user_id) and fragment("lower(?)", r.slug) == ^String.downcase(slug),
      limit: 1
  end
  def get_repository_by_owner_id_and_slug(nil, user_id, slug) do
    Repo.one from r in Repository,
      where: is_nil(r.organisation_id) and r.user_id == ^user_id and fragment("lower(?)", r.slug) == ^String.downcase(slug),
      limit: 1
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
                user: :slug],
      limit: 1
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
