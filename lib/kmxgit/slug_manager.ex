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
      where: fragment("lower(?)", s.slug) == ^String.downcase(slug),
      preload: [organisation: [:slug,
                               owned_repositories: [members: :slug,
                                                    organisation: [:slug,
                                                                   :users],
                                                    user: :slug],
                               users: :slug],
                user: [:slug,
                       organisations: :slug,
                       owned_repositories: [members: :slug,
                                            organisation: :slug,
                                            user: :slug]]],
      limit: 1
  end

  def delete_slug(%Slug{} = slug) do
    Repo.delete(slug)
  end
end
