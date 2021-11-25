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
    many_to_many :members, User, join_through: "users_repositories", on_replace: :delete, on_delete: :delete_all
    timestamps()
  end

  def changeset(repository, attrs \\ %{}) do
    repository
    |> cast(attrs, [:description, :slug])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r|^[A-Za-z][-_+.0-9A-Za-z]{1,64}(/[A-Za-z][-_+.0-9A-Za-z]{1,64})*$|)
    |> unique_constraint(:slug, name: "repositories__lower_slug_index")
    |> Markdown.validate_markdown(:description)
  end

  def owner(%__MODULE__{organisation: org = %Organisation{}}) do
    org
  end
  def owner(%__MODULE__{user: user = %User{}}) do
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

  def members(repo) do
    if repo.user do
      Enum.concat [repo.user], repo.members
    else
      if repo.organisation do
        Enum.concat repo.organisation.users, repo.members
      end
    end
    |> Enum.uniq
  end

  def auth(repo) do
    repo
    |> members()
    |> Enum.sort(fn a, b ->
      a.slug.slug < b.slug.slug
    end)
    |> Enum.map(fn user ->
      mode = if user.deploy_only do
          "r"
        else
          "rw"
        end
      "#{user.slug.slug} #{mode} \"#{full_slug(repo)}.git\"\n"
    end)
  end
end
