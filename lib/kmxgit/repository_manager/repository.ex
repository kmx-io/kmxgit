defmodule Kmxgit.RepositoryManager.Repository do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.RepositoryManager
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "repositories" do
    field :deploy_keys, :string
    field :description, :string
    belongs_to :organisation, Organisation
    field :slug, :string
    belongs_to :user, User
    many_to_many :members, User, join_through: "users_repositories", on_replace: :delete, on_delete: :delete_all
    timestamps()
  end

  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:deploy_keys, :description, :slug])
    |> common_changeset()
  end

  def owner_changeset(repository, attrs, owner = %Organisation{}) do
    repository
    |> cast(attrs, [:deploy_keys, :description, :slug])
    |> put_assoc(:organisation, owner)
    |> put_assoc(:user, nil)
    |> common_changeset()
  end
  def owner_changeset(repository, attrs, owner = %User{}) do
    repository
    |> cast(attrs, [:deploy_keys, :description, :slug])
    |> put_assoc(:organisation, nil)
    |> put_assoc(:user, owner)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> validate_required([:slug])
    |> validate_format(:slug, ~r|^[A-Za-z][-_+.@0-9A-Za-z]{0,64}(/[A-Za-z][-_+.@0-9A-Za-z]{0,64})*$|)
    |> validate_required_owner()
    |> validate_unique_slug()
    |> Markdown.validate_markdown(:description)
  end

  defp validate_required_owner(changeset) do
    org = get_field(changeset, :organisation)
    user = get_field(changeset, :user)
    owner = org || user
    if owner do
      changeset
    else
      changeset
      |> add_error(:organisation, "can't be blank")
      |> add_error(:user, "can't be blank")
    end
  end

  defp validate_unique_slug(changeset = %Ecto.Changeset{valid?: true}) do
    org = get_field(changeset, :organisation)
    user = get_field(changeset, :user)
    owner = org || user
    slug = get_field(changeset, :slug)
    if repo = RepositoryManager.get_repository_by_owner_and_slug(owner.slug.slug, slug) do
      if repo.id != changeset.data.id do
        changeset
        |> add_error(:slug, "is already taken")
      else
        changeset
      end
    else
      changeset
    end
  end
  defp validate_unique_slug(changeset) do
    changeset
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
    full_slug = full_slug(repo)
    auth = repo
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
      auth_line(user.slug.slug, mode, full_slug)
    end)
    auth ++ [auth_line(deploy_user(repo), "r", full_slug)]
  end

  defp auth_line(user, mode, slug) do
    "#{user} #{mode} '#{slug}.git'\n"
  end

  def deploy_user(repo) do
    slug = repo |> full_slug() |> String.replace(~r(.+/), "__")
    "_deploy_#{slug}"
  end

  def deploy_keys_with_env(repo) do
    (repo.deploy_keys || "")
    |> String.split("\n")
    |> Enum.map(fn line ->
      if Regex.match?(~r/^[ \t]*ssh-/, line) do
        "environment=\"GIT_AUTH_ID=#{deploy_user(repo)}\" #{line}"
      else
        line
      end
    end)
    |> Enum.join("\n")
  end
end
