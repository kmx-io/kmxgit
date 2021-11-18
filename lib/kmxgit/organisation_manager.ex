defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug

  def list_organisations do
    Repo.all from org in Organisation, preload: :slug
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
      limit: 1
  end

  def get_organisation_by_slug(slug) do
    Repo.one from o in Organisation,
      join: s in Slug,
      on: s.organisation_id == o.id,
      where: s.slug == ^slug,
      preload: :slug,
      preload: [users: :slug]
  end

  def delete_organisation(%Organisation{} = organisation) do
    Repo.delete(organisation)
  end
end
