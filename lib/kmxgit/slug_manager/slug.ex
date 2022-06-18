defmodule Kmxgit.SlugManager.Slug do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "slugs" do
    field :slug, :string
    belongs_to :organisation, Organisation
    belongs_to :user, User
    timestamps()
  end

  def common_changeset(changeset) do
    changeset
    |> validate_required([:slug])
    |> validate_format(:slug, ~r/^[A-Za-z][-_+.0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:slug)
  end

  def changeset(slug, attrs \\ %{}) do
    slug
    |> cast(attrs, [:slug])
    |> common_changeset()
  end

  def create_changeset(slug, attrs \\ %{}) do
    slug
    |> cast(attrs, [:slug, :organisation_id, :user_id])
    |> common_changeset()
  end
end
