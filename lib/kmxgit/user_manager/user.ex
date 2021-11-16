defmodule Kmxgit.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.UserManager.UserOrganisation
  alias KmxgitWeb.Router.Helpers, as: Routes
  alias BCrypt

  schema "users" do
    field :description, :string, null: true
    field :email, :string, unique: true
    field :encrypted_password, :string
    field :is_admin, :boolean, null: false
    field :login, :string, unique: true
    field :name, :string
    timestamps()
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    has_many :organisations, UserOrganisation
  end

  defp common_changeset(user) do
    user
    |> check_password_confirmation()
    |> put_password_hash()
    |> validate_required([:email, :login, :encrypted_password])
    |> validate_format(:email, ~r/^[-_.0-9A-Za-z]+@([-_0-9A-Za-z]+[.])+[A-Za-z]+$/)
    |> validate_format(:login, ~r/^[A-Za-z][-_0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:_lower_email)
    |> unique_constraint(:_lower_login)
    |> Markdown.validate_markdown(:description)
  end

  @doc false
  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:description, :email, :login, :name, :password, :password_confirmation])
    |> common_changeset()
  end

  @doc false
  def admin_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:description, :email, :is_admin, :login, :name, :password, :password_confirmation])
    |> common_changeset()
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password: password,
                                                              password_confirmation: password_confirmation}} = changeset) do
    if password != password_confirmation do
      Ecto.Changeset.add_error(changeset,
        :password_confirmation,
        "Passwords do not match.")
    else
      changeset
    end
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password: _}} = changeset) do
    changeset
  end

  defp check_password_confirmation(%Ecto.Changeset{changes: %{password_confirmation: _}} = changeset) do
    changeset
  end

  defp check_password_confirmation(changeset) do
    changeset
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

  def after_login_path(user) do
    Routes.user_path(KmxgitWeb.Endpoint, :show, user.login)
  end

  def after_register_path(user) do
    Routes.user_path(KmxgitWeb.Endpoint, :show, user.login)
  end

  def display_name(user) do
    user.name || user.login
  end

end
