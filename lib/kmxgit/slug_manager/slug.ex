defmodule Kmxgit.SlugManager.Slug do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "slugs" do
    field :slug, :string, unique: true
    belongs_to :organisation, Organisation
    belongs_to :user, User
    timestamps()
  end

  def changeset(slug, attrs \\ %{}) do
    slug
    |> cast(attrs, [:slug])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r/^[A-Za-z][-_+.0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:slug, name: "slugs__lower_slug_index")
  end
end
