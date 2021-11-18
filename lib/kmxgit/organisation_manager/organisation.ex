defmodule Kmxgit.OrganisationManager.Organisation do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.User

  schema "organisations" do
    field :description, :string
    field :name, :string
    many_to_many :users, User, join_through: "users_organisations"
    has_one :slug, Slug
    timestamps()
  end

  @doc false
  def changeset(organisation, attrs \\ %{}) do
    organisation
    |> cast(attrs, [:description, :name])
    |> cast_assoc(:users)
    |> cast_assoc(:slug)
    |> validate_required([:slug])
    |> Markdown.validate_markdown(:description)
  end

end
