defmodule Kmxgit.SlugManager do

  import Ecto.Query, warn: false

  alias Kmxgit.Repo
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.User

  def list_all_slugs do
    Slug
    |> Repo.all()
  end

  def create_slug(slug) when is_binary(slug) do
    %Slug{}
    |> Slug.changeset(%{slug: slug})
    |> Repo.insert()
  end
  def create_slug(%Organisation{id: id, slug_: slug}) do
    %Slug{}
    |> Slug.create_changeset(%{slug: slug, organisation_id: id})
    |> Repo.insert()
  end
  def create_slug(%User{id: id, slug_: slug}) do
    %Slug{}
    |> Slug.create_changeset(%{slug: slug, user_id: id})
    |> Repo.insert()
  end

  def update_slug(slug, attrs) do
    slug
    |> Slug.changeset(attrs)
    |> Repo.update()
  end

  def rename_slug(from, to) do
    slug = Repo.one from s in Slug,
      where: s.slug == ^from
    update_slug(slug, %{slug: to})
  end

  def get_slug(slug) do
    Repo.one from s in Slug,
      where: s.slug == ^slug,
      preload: [organisation: [:users,
                               owned_repositories: [:members,
                                                    :user,
                                                    organisation: [:users]]],
                user: [:organisations,
                       owned_repositories: [:members,
                                            :organisation,
                                            :user]]],
      limit: 1
  end

  def delete_slug(slug) when is_binary(slug) do
    s = Repo.one from s in Slug,
      where: s.slug == ^slug
    if s, do: Repo.delete(s), else: :ok
  end
  def delete_slug(%Slug{} = slug) do
    Repo.delete(slug)
  end
end
