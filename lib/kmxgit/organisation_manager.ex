defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager

  def list_organisations do
    Repo.all from org in Organisation,
      join: s in Slug,
      on: s.organisation_id == org.id,
      preload: :slug,
      order_by: s.slug
  end

  def get_organisation!(id) do
    org = Repo.one from org in Organisation,
      where: org.id == ^id,
      preload: [:slug, :users]
    org || raise Ecto.NoResultsError
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

  def get_organisation(id) do
    Repo.one from organisation in Organisation,
      where: [id: ^id],
      preload: :slug,
      preload: [users: :slug],
      limit: 1
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
    user = UserManager.get_user_by_slug(login)
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
    user = UserManager.get_user_by_slug(login)
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
    Repo.delete(organisation)
  end
end
