defmodule Kmxgit.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias BCrypt

  schema "users" do
    field :deploy_only, :boolean, null: false, default: false
    field :description, :string, null: true
    field :email, :string, unique: true
    field :encrypted_password, :string
    field :is_admin, :boolean, null: false
    field :name, :string
    has_many :owned_repositories, Repository
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    #many_to_many :repositories, Repository, join_through: "users_repositories"
    has_one :slug, Slug, on_delete: :delete_all
    field :ssh_keys, :string
    many_to_many :organisations, Organisation, join_through: "users_organisations", on_delete: :delete_all
    timestamps()
  end

  defp common_changeset(changeset) do
    changeset
    |> check_password_confirmation()
    |> put_password_hash()
    |> cast_assoc(:slug)
    |> validate_required([:deploy_only, :email, :encrypted_password, :is_admin, :slug])
    |> validate_format(:email, ~r/^[-_+.0-9A-Za-z]+@([-_0-9A-Za-z]+[.])+[A-Za-z]+$/)
    |> Markdown.validate_markdown(:description)
    |> unique_constraint(:email, name: "users__lower_email_index")
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:deploy_only, :description, :email, :name, :password, :password_confirmation, :ssh_keys])
    |> common_changeset()
  end

  def admin_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:deploy_only, :description, :email, :is_admin, :name, :password, :password_confirmation, :ssh_keys])
    |> common_changeset()
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password: password,
                                                              password_confirmation: password_confirmation}} = changeset) do
    if password != password_confirmation do
      passwords_do_not_match(changeset)
    else
      changeset
    end
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password: _}} = changeset) do
    passwords_do_not_match(changeset)
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password_confirmation: _}} = changeset) do
    passwords_do_not_match(changeset)
  end

  defp check_password_confirmation(changeset) do
    changeset
  end

  defp passwords_do_not_match(changeset) do
    Ecto.Changeset.add_error(changeset,
      :password_confirmation,
      "Passwords do not match.")
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true,
                                         changes: %{password: password,
                                                    password_confirmation: password}}
                           = changeset) do
    change(changeset, encrypted_password: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset) do
    changeset
  end

  def display_name(user) do
    user.name || user.login
  end

  def ssh_keys_with_env(user) do
    (user.ssh_keys || "")
    |> String.split("\n")
    |> Enum.map(fn line ->
      if Regex.match?(~r/^[ \t]*ssh-/, line) do
        "environment=\"GIT_AUTH_ID=#{user.slug.slug}\" #{line}"
      else
        line
      end
    end)
    |> Enum.join("\n")
  end
end
