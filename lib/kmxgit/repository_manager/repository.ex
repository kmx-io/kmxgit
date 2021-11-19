defmodule Kmxgit.RepositoryManager.Repository do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "repositories" do
    field :description, :string
    belongs_to :organisation, Organisation
    field :slug, :string, unique: true
    belongs_to :user, User
    timestamps()
  end

  def changeset(repository, attrs \\ %{}) do
    repository
    |> cast(attrs, [:description, :slug])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r|^[A-Za-z][-_+.0-9A-Za-z]{1,64}(/[A-Za-z][-_+.0-9A-Za-z]{1,64})*$|)
    |> unique_constraint(:_lower_slug)
    |> Markdown.validate_markdown(:description)
  end

  def owner(repo = %__MODULE__{organisation: org = %Organisation{}}) do
    org
  end
  def owner(repo = %__MODULE__{user: user = %User{}}) do
    user
  end

  def owner_slug(repo) do
    owner(repo).slug.slug
  end

  def full_slug(repo) do
    "#{owner_slug(repo)}/#{repo.slug}"
  end

  def splat(repo) do
    String.split(repo.slug, "/")
  end
end
