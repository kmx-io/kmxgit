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

  def changeset(slug, attrs) do
    slug
    |> cast(attrs, [:slug])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r/^[A-Za-z][-_+.0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:_lower_slug)
  end

  def user_changeset(slug, user, attrs \\ {}) do
    slug
    |> changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> validate_only_user()
  end

  defp validate_only_user(changeset) do
    c = changeset |> validate_required(:user_id)
    if get_field(changeset, :organisation_id) do
      add_error(c, :organisation_id, "cannot be set")
    else
      c
    end
  end

  def organisation_changeset(slug, org, attrs \\ {}) do
    slug
    |> changeset(attrs)
    |> Ecto.Changeset.put_assoc(:organisation, org)
    |> validate_only_organisation()
  end

  defp validate_only_organisation(changeset) do
    c = changeset |> validate_required(:organisation_id)
    if get_field(changeset, :user_id) do
      add_error(c, :user_id, "cannot be set")
    else
      c
    end
  end
end
