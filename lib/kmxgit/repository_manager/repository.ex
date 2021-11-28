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
    |> validate_format(:slug, ~r|^[A-Za-z][-_+.@0-9A-Za-z]{0,64}(/[A-Za-z][-_+.@0-9A-Za-z]{0,64})*$|)
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

  def ssh_url(repo) do
    ssh_root = Application.get_env(:kmxgit, :ssh_url)
    "#{ssh_root}:#{full_slug(repo)}.git"
  end

  def splat(repo) do
    String.split(repo.slug, "/")
  end

  def owners(repo) do
    if repo.user do
      [repo.user]
    else
      if repo.organisation do
        repo.organisation.users
      end
    end
  end

  def owner?(repo, user) do
    repo
    |> owners()
    |> Enum.find(fn u -> u.id == user.id end)
  end

  def members(repo) do
    repo
    |> owners()
    |> Enum.concat(repo.members)
    |> Enum.uniq
  end

  def member?(repo, user) do
    repo
    |> members()
    |> Enum.find(fn u -> u.id == user.id end)
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
