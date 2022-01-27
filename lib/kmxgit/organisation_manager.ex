defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager

  @list_preload [:owned_repositories,
                 :slug]

  def list_organisations() do
    update_disk_usage()
    Repo.all from org in Organisation,
      join: s in Slug,
      on: s.organisation_id == org.id,
      preload: ^@list_preload,
      order_by: s.slug
  end
  def list_organisations(%{column: "du", reverse: true}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: [desc: :disk_usage]
  end
  def list_organisations(%{column: "du"}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: :disk_usage
  end
  def list_organisations(%{column: "id", reverse: true}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: [desc: :id]
  end
  def list_organisations(%{column: "id"}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: :id
  end
  def list_organisations(%{column: "name", reverse: true}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: [desc: :name]
  end
  def list_organisations(%{column: "name"}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      preload: ^@list_preload,
      order_by: :name
  end
  def list_organisations(%{column: "slug", reverse: true}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      join: s in Slug,
      on: s.organisation_id == org.id,
      preload: ^@list_preload,
      order_by: [desc: s.slug]
  end
  def list_organisations(%{column: "slug"}) do
    update_disk_usage()
    Repo.all from org in Organisation,
      join: s in Slug,
      on: s.organisation_id == org.id,
      preload: ^@list_preload,
      order_by: s.slug
  end

  def update_disk_usage() do
    orgs = Repo.all(from org in Organisation, preload: :slug)
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
