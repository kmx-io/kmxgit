defmodule Kmxgit.UserManager.UserOrganisation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User
  
  schema "users_organisations" do
    belongs_to :organisation, Organisation
    belongs_to :user, User
    timestamps()
  end

  @doc false
  defp changeset(user_organisation, attrs) do
    user_organisation
    |> cast(attrs, [:organisation_id, :user_id])
  end
end
