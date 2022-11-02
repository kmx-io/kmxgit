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

defmodule Kmxgit.OrganisationManager.Organisation do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.Git
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.User

  schema "organisations" do
    field :description, :string
    field :disk_usage, :integer, default: 0
    field :name, :string
    has_many :owned_repositories, Repository, on_delete: :delete_all
    many_to_many :users, User, join_through: "users_organisations", on_replace: :delete, on_delete: :delete_all
    has_one :slug, Slug, on_delete: :delete_all
    field :slug_, :string
    timestamps()
  end

  @doc false
  def changeset(organisation, attrs \\ %{}) do
    organisation
    |> cast(attrs, [:description, :name, :slug_])
    |> validate_required([:slug_])
    |> Markdown.validate_markdown(:description)
    |> foreign_key_constraint(:owned_repositories, name: :repositories_organisation_id_fkey)
    |> validate_format(:slug_, ~r/^[A-Za-z][-_+.0-9A-Za-z]{1,64}$/)
  end

  def owner?(org, user) do
    if user do
      org.users
      |> Enum.find(fn u ->
        u.id == user.id
      end)
    end
  end

  def owned_repositories(org) do
    if org do
      org.owned_repositories
      |> Enum.sort_by(&Repository.full_slug/1)
    end
  end

  def disk_usage(org) do
    if org do
      Git.dir_disk_usage(org.slug_)
    else
      0
    end
  end
end
