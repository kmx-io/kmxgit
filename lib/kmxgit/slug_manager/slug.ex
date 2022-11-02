## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

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
