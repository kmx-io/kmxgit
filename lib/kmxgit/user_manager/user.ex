defmodule Kmxgit.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias BCrypt

  schema "users" do
    field :description, :string, null: true
    field :email, :string, unique: true
    field :encrypted_password, :string
    field :is_admin, :boolean, null: false
    field :name, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    has_many :repositories, Repository
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
    |> validate_required([:email, :slug, :encrypted_password])
    |> validate_format(:email, ~r/^[-_+.0-9A-Za-z]+@([-_0-9A-Za-z]+[.])+[A-Za-z]+$/)
    |> unique_constraint(:_lower_email)
    |> Markdown.validate_markdown(:description)
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:description, :email, :name, :password, :password_confirmation, :ssh_keys])
    |> common_changeset()
  end

  def admin_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:description, :email, :is_admin, :name, :password, :password_confirmation, :ssh_keys])
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
end
