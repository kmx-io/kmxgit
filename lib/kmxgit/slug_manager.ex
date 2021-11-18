defmodule Kmxgit.SlugManager do

  import Ecto.Query, warn: false

  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug

  def list_slugs do
    Slug
    |> Repo.all
  end

  def create_slug(slug) do
    %Slug{}
    |> Slug.changeset(%{slug: slug})
    |> Repo.insert()
  end

  def update_slug(slug, attrs) do
    slug
    |> Slug.changeset(attrs)
    |> Repo.update()
  end

  def get_slug(slug) do
    Repo.one from s in Slug,
      where: [slug: ^slug],
      preload: [organisation: [:slug, [users: :slug]]],
      preload: [user: [:slug, [organisations: :slug]]],
      limit: 1
  end

  def delete_slug(%Slug{} = slug) do
    Repo.delete(slug)
  end
end
