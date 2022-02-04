defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.IndexParams
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Pagination
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager

  def list_all_organisations(params \\ %IndexParams{}) do
    from(org in Organisation)
    |> join(:inner, [org], s in Slug, on: s.organisation_id == org.id)
    |> order_by([org, s], [asc_nulls_last: fragment("lower(?)", s.slug)])
    |> preload([:owned_repositories, :slug])
    |> Repo.all()
  end

  def list_organisations(params \\ %IndexParams{}) do
    update_disk_usage()
    from(org in Organisation)
    |> join(:inner, [org], s in Slug, on: s.organisation_id == org.id)
    |> search(params)
    |> index_order_by(params)
    |> Pagination.page(params, preload: [:owned_repositories, :slug])
  end

  def search(query, %IndexParams{search: search}) do
    expr = "%#{search}%"
    query
    |> where([org, s], ilike(org.name, ^expr) or ilike(s.slug, ^expr))
  end

  def index_order_by(query, %{column: "id", reverse: true}) do
    order_by(query, [desc: :id])
  end
  def index_order_by(query, %{column: "id"}) do
    order_by(query, :id)
  end
  def index_order_by(query, %{column: "name", reverse: true}) do
    order_by(query, [org, s], [desc_nulls_last: fragment("lower(?)", org.name)])
  end
  def index_order_by(query, %{column: "name"}) do
    order_by(query, [org, s], [asc_nulls_last: fragment("lower(?)", org.name)])
  end
  def index_order_by(query, %{column: "slug", reverse: true}) do
    order_by(query, [org, s], [desc_nulls_last: fragment("lower(?)", s.slug)])
  end
  def index_order_by(query, %{column: "slug"}) do
    order_by(query, [org, s], [asc_nulls_last: fragment("lower(?)", s.slug)])
  end
  def index_order_by(query, %{column: "du", reverse: true}) do
    order_by(query, [desc: :disk_usage])
  end
  def index_order_by(query, %{column: "du"}) do
    order_by(query, :disk_usage)
  end

  def update_disk_usage() do
    Repo.all(from org in Organisation, preload: :slug)
    |> Enum.map(fn org ->
      org
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.put_change(:disk_usage, Organisation.disk_usage(org))
      |> Repo.update!()
    end)
  end

  def put_disk_usage(org = %Organisation{}) do
    %Organisation{org | disk_usage: Organisation.disk_usage(org)}
  end
  def put_disk_usage(orgs) when is_list(orgs) do
    orgs
    |> Enum.map(&put_disk_usage/1)
  end

  def count_organisations do
    Repo.one from org in Organisation, select: count()
  end

  def get_organisation(id) do
    Repo.one from organisation in Organisation,
      where: [id: ^id],
      preload: [:slug,
                owned_repositories: [organisation: :slug,
                                     user: :slug],
                users: :slug],
      limit: 1
  end

  def get_organisation!(id) do
    get_organisation(id) || raise Ecto.NoResultsError
  end

  def change_organisation(organisation \\ %Organisation{}) do
    Organisation.changeset(organisation, %{})
  end

  def create_organisation(user, attrs \\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Repo.insert()
  end

  def update_organisation(organisation, attrs \\ %{}) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  def get_organisation_by_slug(slug) do
    Repo.one from o in Organisation,
      join: s in Slug,
      on: s.organisation_id == o.id,
      where: fragment("lower(?)", s.slug) == ^String.downcase(slug),
      preload: [:slug,
                owned_repositories: [organisation: :slug,
                                     user: :slug],
                users: :slug],
      limit: 1
  end

  def add_user(%Organisation{} = org, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      users = [user | org.users]
      org
      |> Organisation.changeset(%{})
      |> Ecto.Changeset.put_assoc(:users, users)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def remove_user(%Organisation{} = org, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      users = Enum.reject(org.users, &(&1.id == user.id))
      org
      |> Organisation.changeset(%{})
      |> Ecto.Changeset.put_assoc(:users, users)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def delete_organisation(%Organisation{} = organisation) do
    organisation
    |> Organisation.changeset(%{})
    |> Repo.delete()
  end

  def admin_create_organisation(attrs \\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end
end
