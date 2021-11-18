defmodule Kmxgit.OrganisationManager.UserOrganisation do

  use Ecto.Schema

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "users_organisations" do
    belongs_to :user, User
    belongs_to :organisation, Organisation
    belongs_to :invited_by, User, source: :invited_by
    field      :invited_at, :utc_datetime
    field      :invited_ip, :string
    timestamps()
  end

end
