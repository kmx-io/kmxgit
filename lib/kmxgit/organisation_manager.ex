defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.UserManager.User

  def list_organisations do
    Organisation
    |> Repo.all
  end

  def change_organisation(organisation \\ %Organisation{}) do
    Organisation.changeset(organisation, %{})
  end

  def create_organisation(user = %User{id: _}, attrs \\ %{}) do
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
      limit: 1
  end

  def get_organisation_by_slug(slug) do
    Repo.one from organisation in Organisation,
      where: [slug: ^slug],
      limit: 1
  end

  def delete_organisation(%Organisation{} = organisation) do
    Repo.delete(organisation)
  end
end
