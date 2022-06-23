defmodule Kmxgit.RepositoryManager do

  import Ecto.Query, warn: false

  alias Kmxgit.IndexParams
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Pagination
  alias Kmxgit.Repo
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User

  def list_all_repositories() do
    from(r in Repository)
    |> join(:left, [r], o in Organisation, on: o.id == r.organisation_id)
    |> join(:left, [r, o], u in User, on: u.id == r.user_id)
    |> where([r, o, u], not is_nil(r))
    |> order_by([r, o, u], [fragment("concat(lower(?), lower(?))", o.slug_, u.slug_), :slug])
    |> preload([:members,
                :user,
                organisation: [:users]])
    |> Repo.all()
  end

  def list_repositories(params \\ %IndexParams{}) do
    update_disk_usage()
    from(r in Repository)
    |> join(:left, [r], o in Organisation, on: o.id == r.organisation_id)
    |> join(:left, [r, o], u in User, on: u.id == r.user_id)
    |> where([r, o, u], not is_nil(r))
    |> search(params)
    |> index_order_by(params)
    |> Pagination.page(params, preload: [:members,
                                         :user,
                                         organisation: [:users]])
  end

  def search(query, %IndexParams{search: search}) do
    query
    |> where([r, o, u],
         ilike(fragment("concat(?, ?, '/', ?)", o.slug_, u.slug_, r.slug),
           ^"%#{search}%"))
  end

  def index_order_by(query, %IndexParams{column: "id", reverse: true}) do
    order_by(query, [desc: :id])
  end
  def index_order_by(query, %IndexParams{column: "id"}) do
    order_by(query, :id)
  end
  def index_order_by(query, %{column: "owner", reverse: true}) do
    order_by(query, [r, o, u], [desc: fragment("concat(lower(?), lower(?))", o.slug_, u.slug_)])
  end
  def index_order_by(query, %{column: "owner"}) do
    order_by(query, [r, o, u], fragment("concat(lower(?), lower(?))", o.slug_, u.slug_))
  end
  def index_order_by(query, %{column: "slug", reverse: true}) do
    order_by(query, [r, o, u], [desc: fragment("concat(lower(?), lower(?))", o.slug_, u.slug_), desc: :slug])
  end
  def index_order_by(query, %{column: "slug"}) do
    order_by(query, [r, o, u], [fragment("concat(lower(?), lower(?))", o.slug_, u.slug_), :slug])
  end
  def index_order_by(query, %{column: "du", reverse: true}) do
    order_by(query, [desc: :disk_usage])
  end
  def index_order_by(query, %{column: "du"}) do
    order_by(query, :disk_usage)
  end

  def update_disk_usage() do
    Repo.all(from repo in Repository, preload: [:organisation,
                                                :user])
    |> Enum.map(fn repo ->
      repo
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.put_change(:disk_usage, Repository.disk_usage(repo))
      |> Repo.update!()
    end)
  end

  def put_disk_usage(repo = %Repository{}) do
    %Repository{repo | disk_usage: Repository.disk_usage(repo)}
  end
  def put_disk_usage(repos) when is_list(repos) do
    repos
    |> Enum.map(&put_disk_usage/1)
  end

  def count_repositories do
    Repo.one from repo in Repository, select: count()
  end

  def list_contributor_repositories(user) do
    list_all_repositories()
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

  def fork_repository(repo, owner, slug) do
    params = %{description: repo.description,
               slug: slug}
    %Repository{}
    |> Repository.owner_changeset(params, owner, repo)
    |> Repo.insert()
  end

  def update_repository(repository, attrs = %{"owner_slug" => owner_slug}) do
    if owner_slug && owner_slug != "" do
      if slug = SlugManager.get_slug(owner_slug) do
        owner = slug.organisation || slug.user
        IO.inspect([owner_slug: owner_slug, slug: slug, owner: owner])
        if owner do
          repository
          |> Repository.owner_changeset(attrs, owner)
          |> Repo.update()
        else
          raise "invalid slug"
        end
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
      preload: [:members,
                :user,
                organisation: [:slug, :users]])
  end

  def get_repository!(id) do
    get_repository(id) || raise Ecto.NoResultsError
  end

  def get_repository_by_owner_id_and_slug(org_id, nil, slug) do
    Repo.one from r in Repository,
      where: r.organisation_id == ^org_id and is_nil(r.user_id) and r.slug == ^slug,
      limit: 1
  end
  def get_repository_by_owner_id_and_slug(nil, user_id, slug) do
    Repo.one from r in Repository,
      where: is_nil(r.organisation_id) and r.user_id == ^user_id and r.slug == ^slug,
      limit: 1
  end

  def get_repository_by_owner_and_slug(owner, slug) do
    from(r in Repository)
    |> join(:left, [r], o in Organisation, on: o.id == r.organisation_id)
    |> join(:left, [r, o], u in User, on: u.id == r.user_id)
    |> where([r, o, u], (o.slug_ == ^owner or u.slug_ == ^owner) and r.slug == ^slug)
    |> preload([:members, :user, forked_from: [:organisation, :user], organisation: [:users]])
    |> limit(1)
    |> Repo.one()
  end

  def add_member(%Repository{} = repo, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      if ! Enum.find(repo.members, & &1.id == user.id) do
        members = [user | repo.members]
        repo
        |> Repository.changeset(%{})
        |> Ecto.Changeset.put_assoc(:members, members)
        |> Repo.update()
      else
        {:error, :already_a_member}
      end
    else
      {:error, :not_found}
    end
  end

  def remove_member(%Repository{} = repo, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      if Enum.find(repo.members, & &1.id == user.id) do
        members = Enum.reject(repo.members, &(&1.id == user.id))
        repo
        |> Repository.changeset(%{})
        |> Ecto.Changeset.put_assoc(:members, members)
        |> Repo.update()
      else
        {:error, :already_a_member}
      end
    else
      {:error, :not_found}
    end
  end

  def delete_repository(%Repository{} = repo) do
    Repo.delete(repo)
  end
end
