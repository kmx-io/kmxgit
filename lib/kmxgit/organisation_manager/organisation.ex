defmodule Kmxgit.OrganisationManager.Organisation do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.User

  schema "organisations" do
    field :description, :string
    field :name, :string
    has_many :owned_repositories, Repository
    many_to_many :users, User, join_through: "users_organisations", on_delete: :delete_all, on_replace: :delete
    has_one :slug, Slug, on_delete: :delete_all
    timestamps()
  end

  @doc false
  def changeset(organisation, attrs \\ %{}) do
    organisation
    |> cast(attrs, [:description, :name])
    |> cast_assoc(:slug)
    |> validate_required([:slug])
    |> Markdown.validate_markdown(:description)
  end

end
